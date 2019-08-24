/*
Copyright 2014 Ellery Newcomer

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
module pyd.thread;

import std.compiler;

import core.thread;
import util.multi_index;

private bool isAttached = false;

alias ThreadSet = MultiIndexContainer!(
    Thread,
    IndexedBy!(HashedUnique!()),
    MallocAllocator, MutableView
);

__gshared ThreadSet threadSet = null;

shared static this() {
    threadSet = ThreadSet.create();
}

void ensureAttached() {
    if (!isAttached) {
        auto thread = Thread.getThis();
        if(thread is null) {
            thread_attachThis();
            thread = Thread.getThis();
            synchronized(threadSet) {
                threadSet.insert(thread);
            }
        }
        isAttached = true;
    }
}

void detachAll() {
    synchronized(threadSet) {
        foreach(Thread thread; threadSet[]) {
            static if(version_minor >= 67) {
                thread_detachInstance(thread);
            }else{
                // hello, horrible hack
                thread_detachByAddr(getThreadAddr(thread));
            }
        }
        threadSet.clear();
    }
}

static if (version_minor < 67) {
    import core.thread;
    import core.sync.mutex;
    import core.atomic;
    version(Windows) {
        import core.sys.windows.windows;
    }
    version(Posix) {
        import core.sys.posix.sys.types;
    }
    version(OSX) {
        import core.sys.osx.mach.port;
    }

    class _Thread
    {
        __gshared const int PRIORITY_MIN;
        __gshared const int PRIORITY_MAX;
        __gshared const int PRIORITY_DEFAULT;

        enum Call
        {
            NO,
            FN,
            DG
        }

        version( OSX )
        {
            static _Thread       sm_this;
        }
        else version( Posix )
        {
            __gshared pthread_key_t sm_this;
        }
        else
        {
            static _Thread       sm_this;
        }

        __gshared _Thread    sm_main;


        version( Windows )
        {
            HANDLE          m_hndl;
        }
        else version( OSX )
        {
            mach_port_t     m_tmach;
        }
        Thread.ThreadAddr          m_addr;
        Call                m_call;
        string              m_name;
        union
        {
            void function() m_fn;
            void delegate() m_dg;
        }
        size_t              m_sz;
        version( Posix )
        {
            bool            m_isRunning;
        }
        bool                m_isDaemon;
        bool                m_isInCriticalRegion;
        Throwable           m_unhandled;

        static struct Context
        {
            void*           bstack,
                tstack;
            Context*        within;
            Context*        next,
                prev;
        }


        Context             m_main;
        Context*            m_curr;
        bool                m_lock;
        void*               m_tlsgcdata;

        version( Windows )
        {
            version( X86 )
            {
                uint[8]         m_reg; // edi,esi,ebp,esp,ebx,edx,ecx,eax
            }
            else version( X86_64 )
            {
                ulong[16]       m_reg; // rdi,rsi,rbp,rsp,rbx,rdx,rcx,rax
                // r8,r9,r10,r11,r12,r13,r14,r15
            }
            else
            {
                static assert(false, "Architecture not supported." );
            }
        }
        else version( OSX )
        {
            version( X86 )
            {
                uint[8]         m_reg; // edi,esi,ebp,esp,ebx,edx,ecx,eax
            }
            else version( X86_64 )
            {
                ulong[16]       m_reg; // rdi,rsi,rbp,rsp,rbx,rdx,rcx,rax
                // r8,r9,r10,r11,r12,r13,r14,r15
            }
            else
            {
                static assert(false, "Architecture not supported." );
            }
        }


        private:
        __gshared byte[__traits(classInstanceSize, Mutex)][2] _locks;

        __gshared Context*  sm_cbeg;

        __gshared _Thread    sm_tbeg;
        __gshared size_t    sm_tlen;

        _Thread              prev;
        _Thread              next;

    }

    Thread.ThreadAddr getThreadAddr(Thread thread) {
        _Thread* doppelganger = cast(_Thread*) &thread;
        return doppelganger.m_addr;
    }
}
