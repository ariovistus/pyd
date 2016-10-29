module marscamera_c_interface;
/+
 + Minimised code for reproducing PyD segfaults from threading.
 +
 + Author: Michael Walsh
 +/
import core.exception: AssertError;

import std.concurrency: spawn, Tid, thisTid, send, receive, receiveTimeout, OwnerTerminated, register, locate;
import std.datetime: dur;
import std.stdio;

shared string last_error = "";

bool connected = false;


int _acquire(int exposure_time_ms);
int _get_image(uint* matrix); // 65536 length
int _camera_close();

void __attach() {
    import core.thread;
    thread_attachThis();
}

void __detach() {
    import core.thread;
    thread_detachThis();
}


//acquire
void message_handler1(Tid thr, string cmd, float var1) {
	if (cmd == "acquire") {
		int ret = _acquire(var1);
		send!(string, int)(thr, cmd, ret);
	}
}


//get_image, close
void message_handler5(Tid thr, string cmd) {
	if (cmd == "get_image") {
		uint[65536] image;
		uint* tmp = cast(uint*)image;
		int ret = _get_image(tmp);
		send!(string, int, uint[65536])(thr, cmd, ret, image);
	} else if (cmd == "camera_close") {
		int ret = _camera_close();
		if (ret) {
			connected = false;
		}
		send!(string, int)(thr, cmd, ret);
	}
}


void listener(Tid t) {
	send(t, "find", 1);
	while (connected) {
		receive(&message_handler1,  // (Tid, string, float)
			&message_handler5,
			(OwnerTerminated s) {connected = false;}); // (Tid, string)
	}
}

void _camera_find(Tid t, string ip_address) {
	try {
		connected = true;
		listener(t);
	} catch (Exception e) {
		last_error = e.msg.idup;
	} catch (AssertError e) {
		last_error = "Assertion error" ~ e.msg.idup;
	}

}

int camera_find(string ip) {
	scope(failure) {last_error = "Exception in camera_find"; return 0;}
	if (locate("listener") == Tid.init) {
		Tid listener_thread = spawn(&_camera_find, thisTid(), ip);
		register("listener", listener_thread);
		int ret = -1;
		receiveTimeout(dur!"msecs"(5000),
			       (string s, int _ret) {
				       assert(s == "find");
				       ret = _ret;
			       });
		if (ret == -1) {
			last_error = "Timeout on camera find";
			return 1;
		} else {
			return ret;
		}
	} else {
		last_error = "camera_find exception: camera already connected";
		return 0;
	}
}


int _acquire(float exposure_time_ms) {
	//The real version of this code acquires on the camera, which has approximately 500 ms of delay.
	return 1;
}

int acquire(float exposure_time_ms) {
	try {
		auto listener_thread = locate("listener");
		if (listener_thread != Tid.init) {
			send!(Tid, string, float)(listener_thread, thisTid(), "acquire", exposure_time_ms);
			int ret = -1;
                        /*
			receiveTimeout(dur!"msecs"(3000),
				       (string s, int _ret) {
					       assert(s == "acquire");
					       ret = _ret;
				       });
                                       */
			if (ret == -1) {
				last_error = "Timeout on receive response";
				return 1;
			} else {
				return ret;
			}
		} else {
			last_error = "Camera not initialised with 'find'";
			return 0;
		}
	} catch (Exception e) {
		last_error = e.msg.idup;
		return 0;
	} catch (AssertError e) {
		last_error = "Assertion error" ~ e.msg.idup;
		return 0;
	}
}

int _get_image(uint *matrix) {
	// The real version of this code overwrites *matrix with a 65536-long array of data.
	return 1;
}

extern(C) int get_image(uint *matrix) {
	auto listener_thread = locate("listener");
	if (listener_thread != Tid.init) {
		send!(Tid, string)(listener_thread, thisTid(), "get_image");
		int ret = -1;
		receiveTimeout(dur!"msecs"(1000),
			       (string s, int _ret, uint[65536] _matrix) {
				       assert(s == "get_image");
				       foreach (i; 0..65536) {
					       matrix[i] = _matrix[i];
				       }
				       ret = _ret;
			       });
		if (ret == -1) {
			last_error = "get_image: Timeout on receive response";
			return 0;
		} else {
			return ret;
		}
	} else {
		last_error = "Camera not initialised with 'find'";
		return 0;
	}
}

int _camera_close() {
	// The real version of this code closes the socket connection.
	return 1;
}

int camera_close() {
	auto listener_thread = locate("listener");
	if (listener_thread != Tid.init) {
		send!(Tid, string)(listener_thread, thisTid(), "camera_close");
		int ret = -1;
		receiveTimeout(dur!"msecs"(1000),
			       (string s, int _ret) {
				       assert(s == "camera_close");
				       ret = _ret;
			       });
		if (ret == -1) {
			last_error = "camera_close: Timeout on receive response";
			return 0;
		} else {
			return ret;
		}
	} else {
		last_error = "Camera not initialised with 'find'";
		return 0;
	}
}

void __throw_last_error() {
	throw new Exception(last_error);
}

/+
 + Code used for the PyD interface.
 +/

void __camera_find(string ip_address) {
	scope(failure) 	__throw_last_error();
	if (!camera_find(ip_address)) {
		__throw_last_error();
	}
}

void __camera_close() {
	scope(failure) 	__throw_last_error();
	if (!camera_close()) {
		__throw_last_error();
	}
}

void __acquire(float exposure_time_ms) {
	scope(failure) 	__throw_last_error();
	if (!acquire(exposure_time_ms)) {
		__throw_last_error();
	}
}

uint[65536] __get_image() {
	scope(failure) {
            __throw_last_error();
        }
	uint[65536] matrix;
	if (!get_image(cast(uint*)matrix)) {
		//__throw_last_error();
	}
	return matrix;
}
