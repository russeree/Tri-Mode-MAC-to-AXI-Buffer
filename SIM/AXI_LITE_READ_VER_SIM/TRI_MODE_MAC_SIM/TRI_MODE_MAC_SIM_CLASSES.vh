/** 
 * Creator: Reese Russell
 * Date: 12/19/2015
 * Classes Include File
 */
  
 /**
  * Class Random int generator with seed and range 
  */
class random_range_seed;
    typedef struct packed{
        int low,high;
    } low_high;
    int seed = 42;
    low_high range = {0,10};
    function int rand_range_gen;
        int out;
        out = range.low + {$random(seed)} % (range.high - range.low);
        return out; 
    endfunction
endclass