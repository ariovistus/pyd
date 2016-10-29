import std.stdio;
import std.traits;
import dunit;
import std.compiler;
import pyd.pyd, pyd.embedded;
import pyd.references, pyd.func_wrap;
import deimos.python.Python;

class Tests {
    mixin UnitTest;

    /// something changed in 2.067 so that system seems to be the default
    /// attribute, not none.
    @Test public void CheckFunctionAttributes() {
        auto fun = function() {
            return 22;
        };
        alias S = typeof(fun);
        alias T = SetFunctionAttributes!(
                S,
                functionLinkage!S,
                FunctionAttribute.none
                );

        static if(version_major == 2 && version_minor >= 67) {
            assertEquals(FunctionAttribute.system, functionAttributes!T);
        }else{
            assertEquals(FunctionAttribute.none, functionAttributes!T);
        }
    }

    static if(version_major == 2 && version_minor >= 67) {
        /// if we strip away to system, is system all that is left?
        @Test public void CheckFunctionAttribute_System() {
            auto fun = function() {
                return 22;
            };
            alias S = typeof(fun);
            alias T = SetFunctionAttributes!(
                    S,
                    functionLinkage!S,
                    FunctionAttribute.system
                    );

            assertEquals(FunctionAttribute.system, functionAttributes!T);
        }
    }

    @Test public void check_get_reference() {
        alias FA = FunctionAttribute;
        auto fun = function() {
            return 22;
        };
        alias S = typeof(fun);
        alias F = StripFunctionAttributes!S;
        assertEquals(
                FA.pure_ |
                FA.nothrow_ |
                FA.safe |
                FA.nogc,
                functionAttributes!S);

        PyObject* result = d_to_python(fun);
        alias container = pyd_references!(int function()).container;
        auto range = container.python.equalRange(result);
        assertFalse(range.empty);
        assertEquals(functionAttributes!S, range.front.functionAttributes);
        assertFalse(isConversionAddingFunctionAttributes(range.front.functionAttributes, functionAttributes!F));
        //assertEquals(StrippedFunctionAttributes, range.front.functionAttributes);
        // get_d_reference!(int function())(result);
    }
}

mixin Main;
