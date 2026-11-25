/**
* Name: surimi5km
* Author: LENOVO
*/

model surimi5km

global {
    file shape_file_grid <- shape_file("../includes/grid5km.shp");
    file shape_ports <- shape_file("../includes/harbs_df_sf.shp");
    file shape_sub_grid  <- shape_file("../includes/stecf_fulldata.shp");

    // Correct Map Initialization
    map<string, map<string, list<int>>> id_grids_by_vessel <- [];
    map<string, float> grpest_perday_by_length  <- [
    "VL2440" :: 148.9093,
    "VL1824" :: 145.5460,
    "VL1218" :: 129.6214
];

	map<string, float> gamma_shape_by_length <- [
		"VL1218" :: 4.48,
		"VL1824" :: 4.35,
		"VL2440" :: 1.57 
	];
	
	map<string, float> gamma_scale_by_length <- [
		"VL1218" :: 7.75,
		"VL1824" :: 4.59,
		"VL2440" :: 18.9
	];
    
    list<string> months <- [
        "January","February","March","April","May","June",
        "July","August","September","October","November","December"
    ];
    map<string, map<string, float>> landing_m_by_cell_month <- [];
    int current_month_index <- 0;
    string current_month -> months[current_month_index];
//    int days_in_month <- 30;
//    int day_of_month <- 0;
	int fishday_scenario <- 5;
	float beta <- 0.01;
    
    geometry shape <- envelope(shape_file_grid);
    string scenario <- "baseline";

    init {
        // 1. Load Grid
create cell from: shape_file_grid with: [
    id :: string(read("id"))
];

        // 2. Load Sub-Grid Data
        create sub_grid from: shape_sub_grid with: [
            harbour_name       :: string(read("HARBOUR")),
            vessel_name        :: string(read("CFR")),
            vessel_length      :: string(read("VL")),
            vessel_gear        :: string(read("Gear")),
            vessel_origharbour :: string(read("HARBOUR")),
            id_grid            :: int(read("id_grid")),
            MONTH              :: string(read("MONTH")),
            fishday            :: int(read("fishdys")),
            landing			   :: float(read("lndng__")),
            landing_m          :: float(read("lndng_m"))
        ];
        
        loop s over: sub_grid {
    string gid <- string(s.id_grid);

    if !(landing_m_by_cell_month contains_key gid) {
        landing_m_by_cell_month[gid] <- [] as map<string, float>;
    }

    map<string, float> month_map <- landing_m_by_cell_month[gid];

    if !(month_map contains_key s.MONTH) {
        month_map[s.MONTH] <- s.landing_m;
    }


}
        
        
        list<int> unique_ids <- remove_duplicates(sub_grid collect each.id_grid);

		create harbour from: shape_ports with: [
			name :: string(read("HARBOUR"))
		];
    
        // Create Vessels
        list<string> unique_vessel_names <- remove_duplicates(sub_grid collect each.vessel_name);
        loop v over: unique_vessel_names {
            create vessel {
                name <- v;
                list<sub_grid> v_data_list <- sub_grid where (each.vessel_name = name);
                if !empty(v_data_list) {
                    sub_grid v_data <- first(v_data_list);
                    vlength <- v_data.vessel_length;
                    gear <- v_data.vessel_gear;
                    origin_port <- v_data.vessel_origharbour;
                    grpest_perday <- grpest_perday_by_length[vlength];
                //    write "vlength = " + vlength + " grpest_perday = " + grpest_perday;
                
                	// for the gamma distribution lnd_capacity
                	float shape_param <- gamma_shape_by_length[vlength];
                	float scale_param <- gamma_scale_by_length[vlength];
                	
                	lnd_capacity <- gamma_rnd(shape_param, scale_param);

                    harbour home <- harbour first_with (each.name = origin_port);
                    if (home != nil) {
                        location <- home.location;
                    } else {
                        location <- (union(v_data_list collect each.shape)).location;
                    }
                }
                
            }
        }

        // 5. Build lookup map
        loop s over: sub_grid {
            if !(id_grids_by_vessel contains_key s.vessel_name) {
                id_grids_by_vessel[s.vessel_name] <- [] as map<string, list<int>>;
            }
            map<string, list<int>> month_map <- id_grids_by_vessel[s.vessel_name];
            if (!(month_map contains_key s.MONTH)) {
                month_map[s.MONTH] <- [] as list<int>;
            }
            month_map[s.MONTH] << s.id_grid;
        }
        
        // Explicitly initialize vessel data for the first month (January) right away
        do assign_vessel_monthly_data;
    }

    // Encapsulated action to ensure consistency between init and monthly transitions
    action assign_vessel_monthly_data {
        string target_month <- months[current_month_index];
                
        ask vessel {
        	
        	do reset_vessel_data;
        	
            map<string, list<int>> lookup <- id_grids_by_vessel[name];
            if (lookup != nil and lookup contains_key target_month) {
                list<int> ids <- lookup[target_month];
//                list<float> lnd <- lookup[target_month];
                if (!empty(ids)) {
                	list<sub_grid> my_month_data <- sub_grid where 
    ((each.vessel_name = name) and (each.MONTH = target_month));

if !empty(my_month_data) {
    current_id_grid <- my_month_data collect each.id_grid;
    current_landing <- my_month_data collect each.landing;
    current_fishday <- my_month_data collect each.fishday;
    landing_collected_monthly <- 0.0;
    current_grid_index <- 0;
    grp_done_for_month <- false;
} else {
    do reset_vessel_data;
} 

            } 
        }
    }
}


reflex move_vessels_daily {
	if (scenario = "baseline"){
     ask vessel {

        if (!empty(current_id_grid) and
            current_grid_index < length(current_id_grid)) {

            int next_id <- current_id_grid[current_grid_index];
            int next_fishday <- current_fishday[current_grid_index];

            cell target_cell <- cell first_with
                (int(each.id) = next_id);

            harbour home <- harbour first_with
                (each.name = origin_port);

            if (next_fishday <= 0) {

                // Skip grids without fishing days
                current_grid_index <- current_grid_index + 1;
                fishdays_in_current_grid <- 0;

            } else if (target_cell != nil and home != nil) {

                if (trip_phase = "departure") {

                    // Move from harbour to fishing grid
                    location <- target_cell.location;

                    // Collect daily share of observed landings
                    float catch_value <-
                        current_landing[current_grid_index]
                        / float(next_fishday);

                    landing_collected_monthly <-
                        landing_collected_monthly + catch_value;

                    // Subtract landings from the grid
                    if (landing_m_by_cell_month contains_key string(next_id) and
                        landing_m_by_cell_month[string(next_id)] contains_key current_month) {

                        landing_m_by_cell_month[string(next_id)][current_month] <-
                            max([
                                0.0,
                                landing_m_by_cell_month[string(next_id)][current_month]
                                - catch_value
                            ]);
                    }

                    trip_phase <- "return";

                } else if (trip_phase = "return") {

                    // Return to origin harbour
                    location <- home.location;

                    // One fishing day completed
                    fishdays_in_current_grid <-
                        fishdays_in_current_grid + 1;

                    fishdays_completed <-
                        fishdays_completed + 1;

                    // Accumulate GRP for one fishing day
                    grp_cumulative <-
                        grp_cumulative + grpest_perday;

                    // Check whether all fishing days
                    // in this grid have been completed
                    if (fishdays_in_current_grid >= next_fishday) {

                        current_grid_index <-
                            current_grid_index + 1;

                        fishdays_in_current_grid <- 0;
                    }

                    trip_phase <- "departure";
                }
            }
        }

        // Monthly fishing activity completed
        if (current_grid_index >= length(current_id_grid)) {
            trip_phase <- "completed";
        }
    }
}
else {

 ask vessel {

        harbour home <- harbour first_with
            (each.name = origin_port);

        if (trip_phase = "departure") {

            // Identify the eligible cells
            list<int> eligible_ids <- current_id_grid;

            list<cell> eligible_cells <- cell where
                (eligible_ids contains int(each.id));

            if (!empty(eligible_cells) and home != nil) {

                // DISCRETE CHOICE MODEL

                // 1. Calculate systematic utilities
                list<float> utilities <- eligible_cells collect
                    (beta * each.current_landing_m);

                // 2. Maximum utility for numerical stability
                float max_utility <- max(utilities);

                // 3. Exponentiate utilities
                list<float> weights <- utilities collect
                    exp(each - max_utility);

                // 4. Calculate choice probabilities
                float total_weight <- sum(weights);

                list<float> probabilities <- weights collect
                    (each / total_weight);

                // 5. Random selection based on probabilities
                float random_draw <- rnd(1.0);
                float cumulative_prob <- 0.0;

                int chosen_index <- length(eligible_cells) - 1;

                loop i from: 0 to: (length(eligible_cells) - 1) {

                    cumulative_prob <- cumulative_prob
                        + probabilities[i];

                    if (random_draw <= cumulative_prob) {

                        chosen_index <- i;

                        break;
                    }
                }

                // 6. Identify selected cell
                cell target_cell <- eligible_cells[chosen_index];

                // 7. Move to selected fishing cell
                location <- target_cell.location;

                // 8. Collect landings
                float catch_value <- min([
                    lnd_capacity,
                    target_cell.current_landing_m
                ]);

                landing_collected_monthly <-
                    landing_collected_monthly + catch_value;

// from here to veify, it should take based on landing capacity

                // 9. Subtract collected landings
                string next_id <- target_cell.id;

                if (landing_m_by_cell_month contains_key next_id and
                    landing_m_by_cell_month[next_id] contains_key current_month) {

                    landing_m_by_cell_month[next_id][current_month] <-
                        max([
                            0.0,
                            landing_m_by_cell_month[next_id][current_month]
                            - catch_value
                        ]);
                }

                // Return during the following cycle
                trip_phase <- "return";

            } else {

                trip_phase <- "completed";
            }

        } else if (trip_phase = "return") {

            if (home != nil) {

                // Return to origin harbour
                location <- home.location;

                // Complete one fishday
                fishdays_completed <- fishdays_completed + 1;

                // Accumulate daily GRP
                grp_cumulative <- grp_cumulative + grpest_perday;

                // Check monthly fishing effort
                if (fishdays_completed >= fishday_scenario) {

                    trip_phase <- "completed";

                } else {

                    trip_phase <- "departure";
                }
            }
        }
    }
}

}

reflex debug {
    write "Running cycle " + cycle  + " month " + current_month ;
}

reflex update_monthly_data {

    bool change_month <- false;

    if (scenario = "baseline") {

        change_month <- all_match(vessel,
            empty(each.current_id_grid)
            or each.current_grid_index >= length(each.current_id_grid));

    } else {

        change_month <- all_match(vessel,
            each.trip_phase = "completed");
    }

    if (change_month) {

        if (current_month_index = length(months) - 1) {

            do pause;
            write "End of December reached. Simulation finished.";

        } else {

            current_month_index <- current_month_index + 1;
            do assign_vessel_monthly_data;

            if (scenario = "strategies") {

                ask vessel {

                    fishdays_completed <- 0;
                    current_grid_index <- 0;
                    trip_phase <- "departure";

                    harbour home <- harbour first_with
                        (each.name = origin_port);

                    if (home != nil) {
                        location <- home.location;
                    }
                }
            }
        }
    }
}




}



species cell {
    string id;
    rgb landing_color <- #white;

    float current_landing_m -> 
        (landing_m_by_cell_month contains_key id and
         landing_m_by_cell_month[id] contains_key current_month)
        ? landing_m_by_cell_month[id][current_month]
        : 0.0;

  aspect base {
        draw shape color: #blue border: #black;
  }
 

}

species sub_grid {
    string harbour_name; 
    string vessel_name; 
    string vessel_length;
    string vessel_gear; 
    string vessel_origharbour; 
    int id_grid; 
    string MONTH;
    int fishday;
    float landing;
    float  landing_m;
}

species harbour {
    string name;
    aspect base {
        draw circle(2500) color: #red border: #black;
        draw name at: location + {0, 3000} color: #black font: font(10, #bold);
    }
}

species vessel skills: [moving] {
    string name; 
    string vlength; 
    string gear; 
    string origin_port;
    list<int> current_id_grid <- [];
    list<float> current_landing <- [];
    int current_grid_index <- 0;
    list<int> current_fishday <- [];
    float grpest_perday <-  0.00 ;
    float grp_cumulative <- 0.0;
    float fuelcost_day <- 0.0; 
    bool grp_done_for_month <- false;
    float landing_collected_monthly <- 0;
    int fishdays_completed <- 0;
    string trip_phase <- "departure";
    float lnd_capacity <- 0.0;
    int fishdays_in_current_grid <- 0;
    
    // Dynamic scale for drawing
    int vl -> (vlength = "VL1218") ? 1 : ((vlength = "VL1824") ? 2 : ((vlength = "VL2440") ? 3 : 1));
 
action reset_vessel_data {
    current_id_grid <- [];
    current_landing <- [];
    current_grid_index <- 0;
    current_fishday <- [];
    landing_collected_monthly <- 0.0;
    grp_done_for_month <- false;
    fishdays_in_current_grid <- 0;
    fishdays_completed <- 0;
    trip_phase <- "departure";
    
}

    aspect base {
        draw triangle(2000 * vl) color: #green border: #black rotate: 180;
    }
}

experiment surimi type: gui {
	
	parameter "Scenario" var: scenario
    among: ["baseline", "strategies"];
    
    parameter "Fishdays per month"
    var: fishday_scenario
    min: 1
    max: 30
    step: 1;
    
    parameter "Beta" var: beta
    min: 0.0
    max: 0.1
    step: 0.001;
	
    output {
        monitor "Current Month" value: current_month;

       
        display surimi5km type: 2d {
            species cell aspect: base;
            species harbour aspect: base;
            species vessel aspect: base;
        }

        display grp_plot {
            chart "Average GRP by vessel length" type: series {
                data "VL1218" value: mean((vessel where (each.vlength = "VL1218")) collect each.grp_cumulative);
                data "VL1824" value: mean((vessel where (each.vlength = "VL1824")) collect each.grp_cumulative);
                data "VL2440" value: mean((vessel where (each.vlength = "VL2440")) collect each.grp_cumulative);
            }
            }
         
       display landing_plot {
           chart "Landing monthly" type: series {
               data "VL1218" value: median((vessel where (each.vlength = "VL1218")) collect each.landing_collected_monthly);
               data "VL1824" value: median((vessel where (each.vlength = "VL1824")) collect each.landing_collected_monthly);
               data "VL2440" value: median((vessel where (each.vlength = "VL2440")) collect each.landing_collected_monthly);
           }
           }    
            
        } 
}