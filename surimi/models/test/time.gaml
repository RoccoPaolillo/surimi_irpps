/**
* Name: test
* Based on the internal empty template. 
* Author: LENOVO
* Tags: 
*/


model test

global {
	
    float step <- 2 #second; // Each cycle represents 1 hour of simulation time 
    
        reflex check_time {
        // 'time' is a built-in variable (cycle * step)
        write "Total simulated time: " + time + " seconds";
    }
    // This runs every single cycle automatically
    
        reflex periodic_update  when: every(10#cycles) {
        	write "This only happens every 10th tick/cycle";
        	}
    
    reflex update_world {
        write "Current cycle: " + cycle;
        
        // Equivalent to "if ticks = 100 [ stop ]"
        if (cycle = 100) {
            do pause;
        }
    }
    


    
}

experiment test type: gui {


    output {

        display test type: 2d {
            
        }

}
}
    /* Insert your model definition here */

