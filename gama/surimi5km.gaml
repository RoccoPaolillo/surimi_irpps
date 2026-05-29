/**
* Name: surimi5km
* Author: LENOVO
*/

model surimi5km

global {
    file shape_file_grid <- shape_file("../includes/smart5km/grid5km.shp");
    file shape_sub_grid  <- shape_file("../includes/new_data_final/sub_shape5km_new.shp");
    
    // Correct Map Initialization
    map<string, map<string, list<int>>> id_grids_by_vessel <- [];
    map<string, float> grpest_perday_by_length  <- [
    "VL2440" :: 148.9093,
    "VL1824" :: 145.5460,
    "VL1218" :: 129.6214
];
    
    list<string> months <- [
        "January","February","March","April","May","June",
        "July","August","September","October","November","December"
    ];
    int current_month_index <- 0;
    string current_month -> months[current_month_index]; // Dynamic string tracking active month
    
    geometry shape <- envelope(shape_file_grid);

    init {
        // 1. Load Grid
        create cell from: shape_file_grid with: [
           id :: string(read("id"))
        ];

        // 2. Load Sub-Grid Data
        create sub_grid from: shape_sub_grid with: [
            harbour_name       :: string(read("harbour")),
            vessel_name        :: string(read("CFR")),
            vessel_length      :: string(read("VL")),
            vessel_gear        :: string(read("Gear")),
            vessel_origharbour :: string(read("harbour")),
            id_grid            :: int(read("id")),
            MONTH              :: string(read("MONTH")),
            fishday            :: int(read("fishday"))
        ];
        
        list<int> unique_ids <- remove_duplicates(sub_grid collect each.id_grid);

        // 3. Create Harbours
        list<string> unique_harbours <- remove_duplicates(sub_grid collect each.harbour_name);
        loop h over: unique_harbours {
            create harbour {
                name <- h;
                list<sub_grid> my_subs <- sub_grid where (each.harbour_name = name);
                if !empty(my_subs) {
                    location <- (union(my_subs collect each.shape)).location;
                }
            }
        }

        // 4. Create Vessels
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
            map<string, list<int>> lookup <- id_grids_by_vessel[name];
            if (lookup != nil and lookup contains_key target_month) {
                list<int> ids <- lookup[target_month];
                if (!empty(ids)) {
                    current_id_grid <- ids;
                    current_grid_index <- 0;
                    day_in_month <- 0;

                    list<sub_grid> my_month_data <- sub_grid where ((each.vessel_name = name) and (each.MONTH = target_month));
                    if !empty(my_month_data) {
                        current_fishday <- first(my_month_data).fishday;
                    } else {
                        current_fishday <- 0;
                    }
                } else {
                    do reset_vessel_data;
                }
            } else {
                do reset_vessel_data;
            }
        }
       
    }

    /* --- Reflexes --- */

    reflex move_vessels_daily {
        ask vessel {
            if (!empty(current_id_grid) and (current_fishday > 0) and (day_in_month < current_fishday)) {
                int next_id <- current_id_grid[current_grid_index];

                cell target_cell <- cell first_with (int(each.id) = next_id);
                if (target_cell != nil) {
                    location <- target_cell.location;
                }

                current_grid_index <- current_grid_index + 1;
                if (current_grid_index >= length(current_id_grid)) {
                    current_grid_index <- 0;
                }
                
                day_in_month <- day_in_month + 1;
                grp_day <- grp_day + grpest_perday  ;
            }
        }
    }

    // Triggers at the end of every 30-day block
    reflex update_monthly_data when: (cycle > 0) and (cycle mod 30 = 0) {
        if (current_month_index = length(months) - 1) {
            write "End of year reached. Final simulation month processed.";
            do pause;
        } else {
            // Safe increment: Only step forward when the previous month is fully finished
           // string previous_month <- months[current_month_index -1];
           // write "=== End of Month: " + previous_month;
            current_month_index <- current_month_index + 1;
            do assign_vessel_monthly_data;
        }
    }
}

species cell {
    string id;
    int fishavailable <- 3000;
    aspect base { draw shape color: #blue border: #black; }
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
    int current_grid_index <- 0;
    int current_fishday <- 0;
    int day_in_month <- 0;
    float grpest_perday <-  0.00 ;
    float grp_day <- 0.0;
    float fuelcost_day <- 0.0;
    
    // Dynamic scale for drawing
    int vl -> (vlength = "VL1218") ? 1 : ((vlength = "VL1824") ? 2 : ((vlength = "VL2440") ? 3 : 1));
 
    action reset_vessel_data {
        current_id_grid <- [];
        current_grid_index <- 0;
        current_fishday <- 0;
        day_in_month <- 0;
    }

    aspect base {
        draw triangle(2000 * vl) color: #green border: #black rotate: 180;
    }
}

experiment surimi type: gui {
    output {
        monitor "Current Month" value: current_month;
        monitor "Day in month" value: ((cycle mod 30) = 0) ? 30 : (cycle mod 30);
        display surimi5km type: 2d {
            species cell aspect: base;
            species harbour aspect: base;
            species vessel aspect: base;
        }
    }
}
