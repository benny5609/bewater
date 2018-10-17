//
// $id: random.c O $
//

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include <time.h>
#include <string.h>
#include <assert.h>

#define BASKET_SIZE 1000
#define PER_BASKET 8

static uint8_t arr[BASKET_SIZE][128] = {{0}}; //  128 x 8 = 1024bit

static int rand_value()
{
    return (int)fmax(0, fmin(BASKET_SIZE - 1, (double)rand() / RAND_MAX * BASKET_SIZE));
}

static void shuffle(int slot)
{
    int mask_count = 0;
    
    int bit = 0;
    for (bit = 0; bit < BASKET_SIZE; bit++) {
        int ai = bit / PER_BASKET;
        int aj = bit % PER_BASKET;
        int random_count = rand_value();
        int bi = random_count / PER_BASKET;
        int bj = random_count % PER_BASKET;
        uint8_t a = arr[slot][ai] >> aj & 0x1;
        uint8_t b = arr[slot][bi] >> bj & 0x1;
        
        arr[slot][ai] &= ~(1 << aj);
        arr[slot][ai] |= b << aj;
        
        arr[slot][bi] &= ~(1 << bj);
        arr[slot][bi] |= a << bj;
    }
    
    for (bit = 0; bit < BASKET_SIZE; bit++) {
        int i = bit / PER_BASKET;
        int j = bit % PER_BASKET;
        if ((arr[slot][i] >> j & 0x1) == 1)
            mask_count++;
    }
    
    assert(mask_count == slot + 1);
}

static void init_prob()
{
    static int init = 0;
    int slot;
    int bit;
    
    if (!init)
    {
        init = 1;
        srand((unsigned int)time(NULL));
        
        for (slot = 0; slot < BASKET_SIZE; slot++) {
            for (bit = 0; bit < slot + 1; bit++) {
                int i = bit / PER_BASKET;
                int j = bit % PER_BASKET;
                arr[slot][i] |= 1 << j;
            }
            shuffle(slot);
        }
    }
}

static int random_prob(lua_State *L)
{
    int prob = (int)fmax(1, fmin(BASKET_SIZE, (int)luaL_checknumber(L, 1))) - 1;
    int count = rand_value();
    int i = count / PER_BASKET;
    int j = count % PER_BASKET;
    
    assert(prob >= 0 && prob < BASKET_SIZE);
    
    lua_pushboolean(L, (arr[prob][i] >> j & 0x1) == 1);
    
    return 1;
}

static int range_prob_cmp(const void *a, const void *b)
{
    return (*(uint32_t *)b & 0xFFFF) - (*(uint32_t *)a & 0xFFFF);
}

static int random_range_prob(lua_State *L)
{
    lua_settop(L, 1);
    luaL_checktype(L, 1, LUA_TTABLE);
    lua_pushvalue(L, lua_upvalueindex(1));
    lua_pushvalue(L, lua_upvalueindex(2));
    
    int length = lua_rawlen(L, 1);
    int total = 0;
    int idx = 0;

    if (length > BASKET_SIZE)
    {
        lua_pushfstring(L, "length too larger, expect less than '%d', got '%d'", BASKET_SIZE, length);
        lua_error(L);
    }
    
    uint16_t *indexes = (uint16_t *)lua_touserdata(L, 2);
    uint32_t *probs = (uint32_t *)lua_touserdata(L, 3);
    
    int i = 0;
    int j = 0;
    for (i = 0; i < length; i++)
    {
        lua_rawgeti(L, 1, i + 1);
        probs[i] = (uint16_t)luaL_checknumber(L, -1) | (i + 1) << 16;
        total += (probs[i] & 0xFFFF);
        lua_pop(L, 1);
    }
    
    if (total == 0)
    {
        lua_pushstring(L, "all prob is zero!!!!");
        lua_error(L);
    }
    
    qsort(probs, length, sizeof(uint32_t), range_prob_cmp);
    
    for (i = 0; i < length; i++)
    {
        int prob = probs[i] & 0xFFFF;
        int index = probs[i] >> 16;
        int num = (int)((double) prob / total * BASKET_SIZE);
        for (j = 0; j < num; j++)
        {
            indexes[idx++] = index;
        }
    }
    
    for (i = 0; idx < BASKET_SIZE; i++)
    {
        if ((probs[i] & 0xFFFF) > 0)
        {
            indexes[idx++] = probs[i % length] >> 16;
        }
    }
    
    for (i = 0; i < BASKET_SIZE; i += 2)
    {
        int j = rand_value();
        uint16_t a = indexes[i];
        uint16_t b = indexes[j];
        indexes[i] = b;
        indexes[j] = a;
    }
    
    lua_pushinteger(L, indexes[rand_value()]);
    
    return 1;
}

LUALIB_API int luaopen_random_core(lua_State *L)
{
    lua_newtable(L);
    
    lua_pushcfunction(L, random_prob);
    lua_setfield(L, -2, "prob");
    
    lua_newuserdata(L, sizeof(uint16_t) * BASKET_SIZE); // for prob index
    lua_newuserdata(L, sizeof(uint32_t) * BASKET_SIZE); // for prob value
    lua_pushcclosure(L, random_range_prob, 2);
    lua_setfield(L, -2, "range_prob");
    
    init_prob();
    
    return 1;
}
