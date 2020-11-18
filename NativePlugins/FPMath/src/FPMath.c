#include <gdnative_api_struct.gen.h>

#include <stdio.h>

#include "FPMathSinLut.h"
#include "FPMathAtanLut.h"

const godot_gdnative_core_api_struct *api = NULL;
const godot_gdnative_ext_nativescript_api_struct *nativescript_api = NULL;

void* fpmath_constructor(godot_object *p_instance, void *p_method_data);
void fpmath_destructor(godot_object *p_instance, void *p_method_data, void *p_user_data);
godot_variant fpmath_to_fixed(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);
godot_variant fpmath_to_float(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);
godot_variant fpmath_add(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);
godot_variant fpmath_sub(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);
godot_variant fpmath_mul(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);
godot_variant fpmath_div(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);
godot_variant fpmath_floor(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);
godot_variant fpmath_ceil(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);
godot_variant fpmath_abs(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);
godot_variant fpmath_sqrt(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);
godot_variant fpmath_sin(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);
godot_variant fpmath_cos(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);
godot_variant fpmath_tan(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);
godot_variant fpmath_atan(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);
godot_variant fpmath_atan2(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);
godot_variant fpmath_acos(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);
godot_variant fpmath_pow(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);
godot_variant fpmath_log(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);
godot_variant fpmath_deg2rad(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);
godot_variant fpmath_rad2deg(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);

godot_variant fpmath_get_one(godot_object *p_instance, void *p_method_data, void *p_user_data);
godot_variant fpmath_get_pi(godot_object *p_instance, void *p_method_data, void *p_user_data);

void GDN_EXPORT godot_gdnative_init(godot_gdnative_init_options *p_options) {
    api = p_options->api_struct;

    // Now find our extensions.
    for (int i = 0; i < api->num_extensions; i++) {
        switch (api->extensions[i]->type) {
            case GDNATIVE_EXT_NATIVESCRIPT: {
                nativescript_api = (godot_gdnative_ext_nativescript_api_struct *)api->extensions[i];
            }; break;
            default: break;
        }
    }
}

void GDN_EXPORT godot_gdnative_terminate(godot_gdnative_terminate_options *p_options) {
    api = NULL;
    nativescript_api = NULL;
}

void GDN_EXPORT godot_nativescript_init(void *p_handle) {
    godot_instance_create_func create = { NULL, NULL, NULL };
    create.create_func = &fpmath_constructor;

    godot_instance_destroy_func destroy = { NULL, NULL, NULL };
    destroy.destroy_func = &fpmath_destructor;

    nativescript_api->godot_nativescript_register_class(p_handle, "FPMath", "Reference", create, destroy);

    godot_method_attributes attributes = { GODOT_METHOD_RPC_MODE_DISABLED };
#define FPMATH_REGISTER_METHOD(METHOD) \
    godot_instance_method METHOD = { NULL, NULL, NULL }; \
    METHOD.method = &fpmath_##METHOD; \
    nativescript_api->godot_nativescript_register_method(p_handle, "FPMath", #METHOD, attributes, METHOD);

    FPMATH_REGISTER_METHOD(to_fixed);
    FPMATH_REGISTER_METHOD(to_float);
    FPMATH_REGISTER_METHOD(add);
    FPMATH_REGISTER_METHOD(sub);
    FPMATH_REGISTER_METHOD(mul);
    FPMATH_REGISTER_METHOD(div);
    FPMATH_REGISTER_METHOD(floor);
    FPMATH_REGISTER_METHOD(ceil);
    FPMATH_REGISTER_METHOD(abs);
    FPMATH_REGISTER_METHOD(sqrt);
    FPMATH_REGISTER_METHOD(sin);
    FPMATH_REGISTER_METHOD(cos);
    FPMATH_REGISTER_METHOD(tan);
    FPMATH_REGISTER_METHOD(atan);
    FPMATH_REGISTER_METHOD(atan2);
    FPMATH_REGISTER_METHOD(acos);
    FPMATH_REGISTER_METHOD(pow);
    FPMATH_REGISTER_METHOD(log);
    FPMATH_REGISTER_METHOD(deg2rad);
    FPMATH_REGISTER_METHOD(rad2deg);

    godot_variant get_default_var;
    api->godot_variant_new_int(&get_default_var, 0);
    godot_string hint_string;
    api->godot_string_new(&hint_string);
    godot_property_attributes get_attributes;
    get_attributes.rset_type = GODOT_METHOD_RPC_MODE_DISABLED;
    get_attributes.type = GODOT_VARIANT_TYPE_INT;
    get_attributes.hint = GODOT_PROPERTY_HINT_NONE;
    get_attributes.hint_string = hint_string;
    get_attributes.usage = GODOT_PROPERTY_USAGE_STORAGE;
    get_attributes.default_value = get_default_var;
    godot_property_set_func set_default = { NULL, NULL, NULL };
#define FPMATH_REGISTER_PROPERTY_GET(GET) \
    godot_property_get_func GET = { NULL, NULL, NULL }; \
    GET.get_func = &fpmath_get_##GET; \
    nativescript_api->godot_nativescript_register_property(p_handle, "FPMath", #GET, &get_attributes, set_default, GET);

    FPMATH_REGISTER_PROPERTY_GET(one);
    FPMATH_REGISTER_PROPERTY_GET(pi);

    api->godot_string_destroy(&hint_string);
}

void* fpmath_constructor(godot_object *p_instance, void *p_method_data) {
    return NULL;
}

void fpmath_destructor(godot_object *p_instance, void *p_method_data, void *p_user_data) {
}

#define _VAR_TO_STR(s) #s
#define CHECK_ARG_COUNT(argc) \
    if (p_num_args != argc) { \
        api->godot_print_error("expected " _VAR_TO_STR(argc) " arguments", __FUNCTION__, __FILE__, __LINE__); \
        api->godot_variant_new_nil(&ret); \
        return ret; \
    }
#define CHECK_DIV_ZERO(val) \
    if (val == FP_ZERO) { \
        api->godot_print_error("divide by zero is not allowed", __FUNCTION__, __FILE__, __LINE__); \
        api->godot_variant_new_nil(&ret); \
        return ret; \
    }
#define CHECK_NEGATIVE(val) \
    if (val < FP_ZERO) { \
        api->godot_print_error("negative value is not allowed", __FUNCTION__, __FILE__, __LINE__); \
        api->godot_variant_new_nil(&ret); \
        return ret; \
    }
#define CHECK_NORMALIZED(val) \
    if (val < -FP_ONE || val > FP_ONE) { \
        api->godot_print_error("beyond [-1, 1] is not allowed", __FUNCTION__, __FILE__, __LINE__); \
        api->godot_variant_new_nil(&ret); \
        return ret; \
    }
#define CHECK_POW_BASE(val) \
    if (val < FP_ZERO) { \
        api->godot_print_error("the pow base(less 0) is not allowed", __FUNCTION__, __FILE__, __LINE__); \
        api->godot_variant_new_nil(&ret); \
        return ret; \
    }
#define CHECK_LOG_BASE(val) \
    if (val <= FP_ZERO || val == FP_ONE) { \
        api->godot_print_error("the log base(less equal 0 or 1) is not allowed", __FUNCTION__, __FILE__, __LINE__); \
        api->godot_variant_new_nil(&ret); \
        return ret; \
    }
#define CHECK_LOG_X(val) \
    if (val <= FP_ZERO) { \
        api->godot_print_error("the log x(less equal 0) is not allowed", __FUNCTION__, __FILE__, __LINE__); \
        api->godot_variant_new_nil(&ret); \
        return ret; \
    }

#define FP_BITS 16 // lower bits, less overflow
static const int64_t FP_ZERO = 0;
static const int64_t FP_ONE = 1LL << FP_BITS;
static const int64_t FP_TWO = 1LL << (FP_BITS + 1);
static const int64_t FP_HALF = 1LL << (FP_BITS - 1);
static const int64_t FP_MAX = 0x7FFFFFFFFFFFFFFFLL;
static const int64_t FP_MIN = 0x8000000000000000LL;
static const int64_t FP_MASK = (1LL << FP_BITS) - 1;
static const int64_t FP_PI = (314159265LL << FP_BITS) / 100000000LL;
static const int64_t FP_PI_TWO = (628318530LL << FP_BITS) / 100000000LL;
static const int64_t FP_PI_HALF = (157079632LL << FP_BITS) / 100000000LL;
static const int64_t FP_PI_QUARTER = (785398163LL << FP_BITS) / 1000000000LL;
static const int64_t FP_E = (271828183LL << FP_BITS) / 100000000LL;
static const int64_t FP_LN_TWO = (693147180LL << FP_BITS) / 1000000000LL;
static const int64_t FP_LOG_TWO_MAX = 1LL << (FP_BITS + 5);
static const int64_t FP_LOG_TWO_MIN = 1LL << (FP_BITS - 10);
static const int64_t FP_MIN_POSITIVE = 1;
static const int64_t FP_180 = 180LL << FP_BITS;


static inline int64_t _fixed_from_godot_variant(godot_variant *p_arg) {
    int64_t fp = 0;
    godot_variant_type type = api->godot_variant_get_type(p_arg);
    if (type == GODOT_VARIANT_TYPE_INT) {
        fp = api->godot_variant_as_int(p_arg) * FP_ONE;
    }
    else if (type == GODOT_VARIANT_TYPE_REAL) {
        double temp = api->godot_variant_as_real(p_arg) * FP_ONE;
        temp += temp >= 0 ? 0.5 : -0.5;
        fp =(int64_t) temp;
    }
    else {
        char err[64];
        sprintf(err, "unsupport type: %d", type);
        api->godot_print_error(err, __FUNCTION__, __FILE__, __LINE__);
    }
    return fp;
}

static inline int64_t _fixed_mul(int64_t a, int64_t b) {
#if 1
    // slower, but less overflow(wider valid number multiple)
    int64_t alo = a & FP_MASK;
    int64_t ahi = a >> FP_BITS;
    int64_t blo = b & FP_MASK;
    int64_t bhi = b >> FP_BITS;
    int64_t ablolo = (uint64_t)alo * (uint64_t)blo >> FP_BITS;
    int64_t ablohi = alo * bhi;
    int64_t abhilo = ahi * blo;
    int64_t abhihi = ahi * bhi << FP_BITS;
    return ablolo + ablohi + abhilo + abhihi;
#else
    // simple multiple witout performing overflow checking
    return a * b >> FP_BITS;
#endif
}

static inline int64_t _fixed_div(int64_t a, int64_t b) {
    // simple divide witout performing overflow checking
    return (a << FP_BITS) / b;
}

static inline int64_t _fixed_abs(int64_t x) {
#if 1
    // branchless implementation, see http://www.strchr.com/optimized_abs_function
    int64_t y = x >> 63;
    return (x + y) ^ y;
#else
    return x < 0 ? -x : x;
#endif    
}

static inline uint64_t _fixed_sqrt(uint64_t x) {
    uint64_t num = x;
    uint64_t y = 0ULL;
    uint64_t bit = 1ULL << 62;
    while (bit > num) bit >>= 2;
    for (int i = 0; i < 2; ++i) {
        while (bit != 0) {
            if (num >= y + bit) {
                num -= y + bit;
                y = (y >> 1) + bit;
            }
            else {
                y = y >> 1;
            }
            bit >>= 2;
        }
        if (i == 0) {
            if (num > (1ULL << FP_BITS) - 1) {
                num -= y;
                num = (num << FP_BITS) - (1LL << (FP_BITS - 1));
                y = (y << FP_BITS) + (1LL << (FP_BITS - 1));
            }
            else {
                num <<= FP_BITS;
                y <<= FP_BITS;
            }
            bit = 1UL << (FP_BITS - 2);
        }
    }
    if (num > y) ++y;
    return y;  
}

static inline int64_t _fixed_sin(int64_t x) {
    int64_t y = x % FP_PI_TWO;
    if (y < 0)
        y += FP_PI_TWO;
    if(y >= FP_PI) {
        y -= FP_PI;
        if(y > FP_PI_HALF)
            y = FP_PI - y;
        y = y * FP_SIN_LUT_SIZE / FP_PI_HALF;
        y = -FP_SIN_LUT[y];//y = -(y >= FP_SIN_LUT_SIZE ? FP_ONE : FP_SIN_LUT[y]);
    } else {
        if(y > FP_PI_HALF)
            y = FP_PI - y;
        y = y * FP_SIN_LUT_SIZE / FP_PI_HALF;
        y = FP_SIN_LUT[y];//(y >= FP_SIN_LUT_SIZE ? FP_ONE : FP_SIN_LUT[y]);
    }
    return y;
}

// ref: https://www.mathworks.com/help/fixedpoint/ref/atan2.html
static inline int64_t _fixed_atan2(int64_t y, int64_t x) {
    // four-quadrant arctangent
    if (x == 0) {
        if (y == 0) return 0;
        return y > 0 ? FP_PI_HALF : -FP_PI_HALF;
    }
#if 0
    if (x > 0) {
        if (y >= 0) {
            if (y < x) {
                y = (y << FP_BITS) / x;
                y = y * FP_ATAN_LUT_SIZE >> FP_BITS;
                y = FP_ATAN_LUT[y];
            }
            else {
                y = (x << FP_BITS) / y;
                y = y * FP_ATAN_LUT_SIZE >> FP_BITS;
                y = FP_PI_HALF - FP_ATAN_LUT[y];
            }
        }
        else {
            y = -y;
            if (y < x) {
                y = (y << FP_BITS) / x;
                y = y * FP_ATAN_LUT_SIZE >> FP_BITS;
                y = -FP_ATAN_LUT[y];
            }
            else {
                y = (x << FP_BITS) / y;
                y = y * FP_ATAN_LUT_SIZE >> FP_BITS;
                y = -(FP_PI_HALF - FP_ATAN_LUT[y]);
            }
        }
    }
    else {
        x = -x;
        if (y >= 0) {
            if (y < x) {
                y = (y << FP_BITS) / x;
                y = y * FP_ATAN_LUT_SIZE >> FP_BITS;
                y = FP_PI - FP_ATAN_LUT[y];
            }
            else {
                y = (x << FP_BITS) / y;
                y = y * FP_ATAN_LUT_SIZE >> FP_BITS;
                y = FP_PI_HALF + FP_ATAN_LUT[y];
            }
        }
        else {
            y = -y;
            if (y < x) {
                y = (y << FP_BITS) / x;
                y = y * FP_ATAN_LUT_SIZE >> FP_BITS;
                y = -(FP_PI - FP_ATAN_LUT[y]);
            }
            else {
                y = (x << FP_BITS) / y;
                y = y * FP_ATAN_LUT_SIZE >> FP_BITS;
                y = -(FP_PI_HALF + FP_ATAN_LUT[y]);
            }   
        }
    }
#else
    // less branch implementation
    static const int _y_signs[2][2][2] = {
        {
            { 1, -1 },
            {-1,  1 },
        },
        {
            {-1,  1 },
            { 1, -1 },
        }
    };
    static const int _y_offset[2][2][2] = {
        {
            { 0,  1 },
            { 0, -1 },
        },
        {
            { 2,  1 },
            {-2, -1 },
        }
    };

    int64_t ay = _fixed_abs(y);
    int64_t ax = _fixed_abs(x);
    int i = x <= 0;
    int j = y < 0;
    int k = ay >= ax;
    y = k ? (ax << FP_BITS) / ay : (ay << FP_BITS) / ax;
    y = y * FP_ATAN_LUT_SIZE >> FP_BITS;
    y = FP_ATAN_LUT[y] * _y_signs[i][j][k] + FP_PI_HALF * _y_offset[i][j][k];
#endif    
    return y;
}

static inline int64_t _fixed_acos(int64_t x) {
    if (x == 0) return FP_PI_HALF;
    int64_t y = _fixed_mul(x, x);
    y = _fixed_sqrt(FP_ONE - y);
    y = _fixed_atan2(y, x);
    return y;
}

static inline int64_t _fixed_pow2(int64_t x) {
    /* The algorithm is based on the power series for exp(x):
     * http://en.wikipedia.org/wiki/Exponential_function#Formal_definition
     * 
     * From term n, we get term n+1 by multiplying with x/n.
     * When the sum term drops to zero, we can stop summing.
     */
    if (x == 0) return FP_ONE;
    bool neg = x < 0;
    if (neg) x = -x;
    if (x == FP_ONE) return neg ? FP_HALF: FP_TWO;
    if (x >= FP_LOG_TWO_MAX) return neg ? FP_MIN_POSITIVE : FP_MAX;
    if (x <= FP_LOG_TWO_MIN) return neg ? FP_MAX : FP_ZERO;
    int integerPart = (x & (~FP_MASK)) >> FP_BITS; // floor
    x = x & FP_MASK; // fractional part
    int64_t y = FP_ONE;
    int64_t term = FP_ONE;
    for (int i = 1; term != 0; i++) {
        term = _fixed_mul(term, x);
        term = _fixed_mul(term, FP_LN_TWO);
        term = term / i; //_fixed_div(term, (int64_t)i << FP_BITS);
        y += term;
    }
    y <<= integerPart; // no overflow by restraint of [FP_LOG_TWO_MIN, FP_LOG_TWO_MAX]
    return neg ? _fixed_div(FP_ONE, y) : y;
}

static inline int64_t _fixed_log2(int64_t x) {
    // The input x must be positive
    // This implementation is based on Clay. S. Turner's fast binary logarithm
    // algorithm (C. S. Turner,  "A Fast Binary Logarithm Algorithm", IEEE Signal
    //     Processing Mag., pp. 124,140, Sep. 2010.)
    int64_t b = 1LL << (FP_BITS - 1);
    int64_t y = 0;
    while (x < FP_ONE) {
        x <<= 1;
        y -= FP_ONE;
    }
    while (x >= FP_TWO) {
        x >>= 1;
        y += FP_ONE;
    }
    for (int i = 0; i < FP_BITS; i++) {
        x = _fixed_mul(x, x);
        if (x >= FP_TWO) {
            x >>= 1;
            y += b;
        }
        b >>= 1;
    }
    return y;
}

godot_variant fpmath_to_fixed(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
    godot_variant ret;
    CHECK_ARG_COUNT(1);
    int64_t fp = _fixed_from_godot_variant(p_args[0]);
    api->godot_variant_new_int(&ret, fp);
    return ret;
}

godot_variant fpmath_to_float(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
    godot_variant ret;
    CHECK_ARG_COUNT(1);
    int64_t fp = api->godot_variant_as_int(p_args[0]);
    double real = (double)fp / FP_ONE;
    api->godot_variant_new_real(&ret, real);
    return ret;
}

godot_variant fpmath_add(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
    godot_variant ret;
    CHECK_ARG_COUNT(2);
    int64_t a = api->godot_variant_as_int(p_args[0]);
    int64_t b = api->godot_variant_as_int(p_args[1]);
    // simple add witout performing overflow checking
    int64_t y = a + b;
    api->godot_variant_new_int(&ret, y);
    return ret;
}

godot_variant fpmath_sub(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
    godot_variant ret;
    CHECK_ARG_COUNT(2);
    int64_t a = api->godot_variant_as_int(p_args[0]);
    int64_t b = api->godot_variant_as_int(p_args[1]);
    // simple subtract witout performing overflow checking
    int64_t y = a - b;
    api->godot_variant_new_int(&ret, y);
    return ret;
}

godot_variant fpmath_mul(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
    godot_variant ret;
    CHECK_ARG_COUNT(2);
    int64_t a = api->godot_variant_as_int(p_args[0]);
    int64_t b = api->godot_variant_as_int(p_args[1]);
    int64_t y = _fixed_mul(a, b);
    api->godot_variant_new_int(&ret, y);
    return ret;
}

godot_variant fpmath_div(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
    godot_variant ret;
    CHECK_ARG_COUNT(2);
    int64_t a = api->godot_variant_as_int(p_args[0]);
    int64_t b = api->godot_variant_as_int(p_args[1]);
    CHECK_DIV_ZERO(b);
    int64_t y = _fixed_div(a, b);
    api->godot_variant_new_int(&ret, y);
    return ret;
}

godot_variant fpmath_floor(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
    godot_variant ret;
    CHECK_ARG_COUNT(1);
    int64_t a = api->godot_variant_as_int(p_args[0]);
    int64_t y = a & (~FP_MASK);
    api->godot_variant_new_int(&ret, y);
    return ret;
}

godot_variant fpmath_ceil(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
    godot_variant ret;
    CHECK_ARG_COUNT(1);
    int64_t a = api->godot_variant_as_int(p_args[0]);
    int64_t y = a & (~FP_MASK);
    if (a & FP_MASK) y += FP_ONE;
    api->godot_variant_new_int(&ret, y);
    return ret;
}

godot_variant fpmath_abs(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
    godot_variant ret;
    CHECK_ARG_COUNT(1);
    int64_t a = api->godot_variant_as_int(p_args[0]);
    int64_t y = _fixed_abs(a);  
    api->godot_variant_new_int(&ret, y);
    return ret;
}

godot_variant fpmath_sqrt(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
    godot_variant ret;
    CHECK_ARG_COUNT(1);
    int64_t a = api->godot_variant_as_int(p_args[0]);
    CHECK_NEGATIVE(a);
    uint64_t y = _fixed_sqrt(a);
    api->godot_variant_new_int(&ret, y);
    return ret;
}

godot_variant fpmath_sin(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
    godot_variant ret;
    CHECK_ARG_COUNT(1);
    int64_t a = api->godot_variant_as_int(p_args[0]);
    int64_t y = _fixed_sin(a);
    api->godot_variant_new_int(&ret, y);
    return ret;
}

godot_variant fpmath_cos(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
    godot_variant ret;
    CHECK_ARG_COUNT(1);
    int64_t a = api->godot_variant_as_int(p_args[0]);
    int64_t y = _fixed_sin(a + FP_PI_HALF);
    api->godot_variant_new_int(&ret, y);
    return ret;
}

godot_variant fpmath_tan(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
    godot_variant ret;
    CHECK_ARG_COUNT(1);
    // smaller abs(angle) more precision
    int64_t a = api->godot_variant_as_int(p_args[0]);
    int64_t c = _fixed_sin(a + FP_PI_HALF);
    CHECK_DIV_ZERO(c); // tan(90°) or tan(270°) ?
    int64_t s = _fixed_sin(a);
    int64_t y = (s << FP_BITS) / c;
    api->godot_variant_new_int(&ret, y);
    return ret;
}

godot_variant fpmath_atan(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
    godot_variant ret;
    CHECK_ARG_COUNT(1);
    int64_t a = api->godot_variant_as_int(p_args[0]);
    int64_t y = _fixed_atan2(a, FP_ONE);
    api->godot_variant_new_int(&ret, y);
    return ret;
}

godot_variant fpmath_atan2(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
    godot_variant ret;
    CHECK_ARG_COUNT(2);
    int64_t a = api->godot_variant_as_int(p_args[0]);
    int64_t b = api->godot_variant_as_int(p_args[1]);
    int64_t y = _fixed_atan2(a, b);
    api->godot_variant_new_int(&ret, y);
    return ret;
}

godot_variant fpmath_acos(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
    godot_variant ret;
    CHECK_ARG_COUNT(1);
    int64_t a = api->godot_variant_as_int(p_args[0]);
    CHECK_NORMALIZED(a);
    int64_t y = _fixed_acos(a);
    api->godot_variant_new_int(&ret, y);
    return ret;
}

godot_variant fpmath_pow(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
    godot_variant ret;
    CHECK_ARG_COUNT(2);
    int64_t a = api->godot_variant_as_int(p_args[0]);
    int64_t b = api->godot_variant_as_int(p_args[1]);
    int64_t y = FP_ZERO;
    if (a == FP_ONE || b == FP_ZERO) {
        y = FP_ONE;
    }
    else if (a != FP_ZERO){
        CHECK_POW_BASE(a);
        y = _fixed_log2(a);
        y = _fixed_mul(y, b);
        y = _fixed_pow2(y);
    }
    api->godot_variant_new_int(&ret, y);
    return ret;
}

godot_variant fpmath_log(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
    godot_variant ret;
    CHECK_ARG_COUNT(2);
    int64_t a = api->godot_variant_as_int(p_args[0]);
    int64_t b = api->godot_variant_as_int(p_args[1]);
    CHECK_LOG_BASE(a);
    CHECK_LOG_X(b);
    int64_t y = _fixed_log2(a);
    int64_t z = _fixed_log2(b);
    CHECK_DIV_ZERO(y);
    y = _fixed_div(z, y);
    api->godot_variant_new_int(&ret, y);
    return ret;
}

godot_variant fpmath_deg2rad(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
    godot_variant ret;
    CHECK_ARG_COUNT(1);
    int64_t a = api->godot_variant_as_int(p_args[0]);
    int64_t y = _fixed_mul(a, FP_PI);
    y = _fixed_div(y, FP_180);
    api->godot_variant_new_int(&ret, y);
    return ret;
}

godot_variant fpmath_rad2deg(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
    godot_variant ret;
    CHECK_ARG_COUNT(1);
    int64_t a = api->godot_variant_as_int(p_args[0]);
    int64_t y = _fixed_mul(a, FP_180);
    y = _fixed_div(y, FP_PI);
    api->godot_variant_new_int(&ret, y);
    return ret;
}

godot_variant fpmath_get_one(godot_object *p_instance, void *p_method_data, void *p_user_data) {
    godot_variant ret;
    api->godot_variant_new_int(&ret, FP_ONE);
    return ret;
}

godot_variant fpmath_get_pi(godot_object *p_instance, void *p_method_data, void *p_user_data) {
    godot_variant ret;
    api->godot_variant_new_int(&ret, FP_PI);
    return ret;
}
