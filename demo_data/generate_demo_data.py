from math import cos, sin
import pandas as pd 
import random
from itertools import product

def get_coordinate(t: int) -> tuple: 
    '''
    Takes a time stamp and returns (X, Y) coordinates of a parametric function
    as a 2-tuple. 
    '''

    X = 3000.0 * cos(0.3*t) + 5000.0
    Y = 5000.0 * sin(0.3*t) + 5000.0

    return X, Y

def get_rand_sensor_error(upper_bound=100): 
    return float(random.randint(1, upper_bound)) - (upper_bound / 2.0)

def toggle_state(state): 
    if state == "stopping": return "moving" 
    else: 
        assert state == "moving"
        return "stopping"

def generate_position_data(start_time: int, end_time: int, cycle_length=20) -> pd.DataFrame: 
    '''
    Generate fake position data sequence according to parametric function 
    defined in get_coordinate(). Will generate movement sequence that move for 
    20 seconds, and then stop for 20 seconds, and repeat. Returns a pandas 
    dataframe with fake data sequence. 
    '''

    if end_time - start_time < cycle_length * 2: 
        raise Exception("Time frame has to be at least 40 seconds. ") 

    param_fn_input = start_time 
    state = "moving" # other state is "stopping"
    curr_state_timer = 0 # count time being under current state
    prev_X, prev_Y = None, None
    DF = pd.DataFrame(columns=["X", "Y", "timestamp", "period", "day"])

    days, periods = range(1,4), range(1,6)

    for day, period in product(days, periods): 
        for actual_time in range(start_time, end_time): 

            if curr_state_timer >= cycle_length: 
                state = toggle_state(state) 
                curr_state_timer = 0

            if state == "moving": 
                X, Y = get_coordinate(param_fn_input)
                param_fn_input += 1
                prev_X, prev_Y = X, Y

            else: # stopping 
                X, Y = prev_X + get_rand_sensor_error(), prev_Y + get_rand_sensor_error()

            DF.loc[len(DF.index)] = [ X, Y, actual_time, period, day ]
            
            curr_state_timer += 1

    return DF

def generate_seating(classroom_width=10000, classroom_height=10000, horizontal_spacing=2000, vertical_spacing=2000) -> pd.DataFrame: 
    '''
    Generate a pandas dataframe with student seat coordinates information. Input 
    variables define classroom layout. 
    '''

    DF = pd.DataFrame(columns=["object", "X", "Y"]) 

    seat_index = 0
    for X in range(horizontal_spacing, classroom_width, horizontal_spacing): 
        for Y in range(vertical_spacing, classroom_height, vertical_spacing): 
            # row format: | seat10 | 100 | 100 |
            DF.loc[len(DF.index)] = [f"seat{seat_index}", X, Y] 
            seat_index += 1

    return DF



if __name__ == "__main__": 

    random.seed(101)

    print("Generating position data ...")
    positionDF = generate_position_data(0, 600) 
    positionDF.to_csv("demo_position_data.csv", index=False)

    print("Generating seating chart ...")
    seatingDF = generate_seating() 
    seatingDF.to_csv("demo_seating_chart.csv", index=False)





