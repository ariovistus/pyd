module util.typelist;

template Join(string delimit, T...) {
        static if(T.length == 0) {
            enum Join = "";
        }else static if(T.length == 1) {
            enum Join =  T[0];
        }else {
            enum Join = T[0] ~ delimit ~ Join!(delimit,T[1..$]);
        }
}
