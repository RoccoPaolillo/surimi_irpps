/**
* Name: surimi5km
* Author: LENOVO
*/

model surimi5km

global {
    file shape_file_grid <- shape_file("../includes/grid5km.shp");
    file shape_ports <- shape_file("../includes/harbs_df_sf.shp");
    file shape_sub_grid  <- shape_file("../includes/stecf_fulldata.shp");
 //   file newdataset <- csv_file("../includes/Full_model_eco_agg_GRP.csv");
//      file shape_sub_grid  <- shape_file("../includes/harbs_df_sf.shp");
    
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
    map<string, map<string, float>> landing_m_by_cell_month <- [];
    int current_month_index <- 0;
    string current_month -> months[current_month_index];
    
    geometry shape <- envelope(shape_file_grid);

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

 //   month_map[s.MONTH] <- month_map[s.MONTH] + s.landing_m;
 


}
        
// ask cell {
//     loop m over: months {
//         list<sub_grid> my_data <- sub_grid where (
 //            (string(each.id_grid) = id) and (each.MONTH = m)
//         );

//         if !empty(my_data) {
//             landing_m_by_month[m] <- sum(my_data collect each.landing_m);
//         } else {
//             landing_m_by_month[m] <- 0.0;
//         }
//     }
// }
        
        list<int> unique_ids <- remove_duplicates(sub_grid collect each.id_grid);

		create harbour from: shape_ports with: [
			name :: string(read("HARBOUR"))
		];
        // 3. Create Harbours
//        list<string> unique_harbours <- remove_duplicates(sub_grid collect each.harbour_name);
//         loop h over: unique_harbours {
//             create harbour {
//                 name <- h;
//                 list<sub_grid> my_subs <- sub_grid where (each.harbour_name = name);
//                 if !empty(my_subs) {
//                     location <- (union(my_subs collect each.shape)).location;
//                 }
//             }
//         }

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
//                list<float> lnd <- lookup[target_month];
                if (!empty(ids)) {
                	list<sub_grid> my_month_data <- sub_grid where 
    ((each.vessel_name = name) and (each.MONTH = target_month));

if !empty(my_month_data) {
    current_id_grid <- my_month_data collect each.id_grid;
    current_landing <- my_month_data collect each.landing;
    current_fishday <- first(my_month_data).fishday;
    landing_collected_monthly <- 0.0;
    current_grid_index <- 0;
    grp_done_for_month <- false;
} else {
    do reset_vessel_data;
} 
//                    current_id_grid <- ids;
//                    current_grid_index <- 0;
//                    grp_done_for_month <- false;

//                   list<sub_grid> my_month_data <- sub_grid where ((each.vessel_name = name) and (each.MONTH = target_month));
//                    if !empty(my_month_data) {
//                        current_fishday <- first(my_month_data).fishday;
//                        current_landing <- my_month_data collect each.landing;
//                        landing_collected_monthly <- 10;
//                   } else {
//                        current_fishday <- 0;
//                    }
//                } else {
//                    do reset_vessel_data;
//                }
//            } else {
//                do reset_vessel_data;
            } 
        }
    }
}
     /* --- Reflexes --- */

// reflex move_vessels_daily {
//     ask vessel {

        // Move one cell per cycle until all monthly cells are covered
// if (!empty(current_id_grid) and current_grid_index < length(current_id_grid)) {

 //    int next_id <- current_id_grid[current_grid_index];

 //    cell target_cell <- cell first_with (int(each.id) = next_id);
//    if (target_cell != nil) {
//         location <- target_cell.location;
//     }

//     if (current_grid_index < length(current_landing)) {
//         landing_collected_monthly <- landing_collected_monthly + current_landing[current_grid_index];
//     }

// if (target_cell != nil) {
//     location <- target_cell.location;
// 
 //    if (current_grid_index < length(current_landing)) {
 //        float catch_value <- current_landing[current_grid_index];

        // vessel collects landing
 //        landing_collected_monthly <- landing_collected_monthly + catch_value;

        // subtract landing from the visited cell for the current month
 //        if (landing_m_by_cell_month contains_key string(next_id) and
  //           landing_m_by_cell_month[string(next_id)] contains_key current_month) {
// 
 //            landing_m_by_cell_month[string(next_id)][current_month] <-
 //                max([
 //                    0.0,
//                     landing_m_by_cell_month[string(next_id)][current_month] - catch_value
//                 ]);
 //        }
//     }
// }

 //    current_grid_index <- current_grid_index + 1;
// }

        // Add monthly GRP only once, after the whole route is completed
//         if (!grp_done_for_month and
//             !empty(current_id_grid) and
//             current_grid_index >= length(current_id_grid)) {
// 
//             grp_day <- grp_day + (grpest_perday * current_fishday);
//             grp_done_for_month <- true;
//         }
//     }
//  }

reflex move_vessels_daily {
    ask vessel {

        if (!empty(current_id_grid) and current_grid_index < length(current_id_grid)) {

            int next_id <- current_id_grid[current_grid_index];

            cell target_cell <- cell first_with (int(each.id) = next_id);

            if (target_cell != nil) {
                location <- target_cell.location;

                if (current_grid_index < length(current_landing)) {
                    float catch_value <- current_landing[current_grid_index];

                    landing_collected_monthly <- landing_collected_monthly + catch_value;

                    if (landing_m_by_cell_month contains_key string(next_id) and
                        landing_m_by_cell_month[string(next_id)] contains_key current_month) {

                        landing_m_by_cell_month[string(next_id)][current_month] <-
                            max([
                                0.0,
                                landing_m_by_cell_month[string(next_id)][current_month] - catch_value
                            ]);
                    }
                }
            }

            current_grid_index <- current_grid_index + 1;
        }

        if (!grp_done_for_month and
            !empty(current_id_grid) and
            current_grid_index >= length(current_id_grid)) {

            grp_day <- grp_day + (grpest_perday * current_fishday);
            grp_done_for_month <- true;
        }
    }
}

reflex debug {
    write "Running cycle " + cycle  + " month " + current_month ;
}

reflex update_monthly_data when:
    all_match(vessel,
        empty(each.current_id_grid)
        or each.current_grid_index >= length(each.current_id_grid)) {

    if (current_month_index = length(months) - 1) {
        do pause;
        write "End of December reached. Simulation finished.";
    } else {
        current_month_index <- current_month_index + 1;
        do assign_vessel_monthly_data;
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
 
 // aspect base {
 //     float max_landing <- max(cell collect each.current_landing_m);

 //     float p <- (max_landing > 0) ? current_landing_m / max_landing : 0.0;

 //     draw shape color: rgb(
 //         int(220 * (1 - p)),
 //         int(220 * (1 - p)),
  //        255
  //    ) border: #black;
 // }



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
    int current_fishday <- 0;
    float grpest_perday <-  0.00 ;
    float grp_day <- 0.0;
    float fuelcost_day <- 0.0; 
    bool grp_done_for_month <- false;
    float landing_collected_monthly <- 0;
    
    // Dynamic scale for drawing
    int vl -> (vlength = "VL1218") ? 1 : ((vlength = "VL1824") ? 2 : ((vlength = "VL2440") ? 3 : 1));
 
action reset_vessel_data {
    current_id_grid <- [];
    current_landing <- [];
    current_grid_index <- 0;
    current_fishday <- 0;
    landing_collected_monthly <- 0.0;
    grp_done_for_month <- false;
}

    aspect base {
        draw triangle(2000 * vl) color: #green border: #black rotate: 180;
    }
}

experiment surimi type: gui {
    output {
        monitor "Current Month" value: current_month;
       
        display surimi5km type: 2d {
            species cell aspect: base;
            species harbour aspect: base;
            species vessel aspect: base;
        }

        display grp_plot {
            chart "Average GRP by vessel length" type: series {
                data "VL1218" value: mean((vessel where (each.vlength = "VL1218")) collect each.grp_day);
                data "VL1824" value: mean((vessel where (each.vlength = "VL1824")) collect each.grp_day);
                data "VL2440" value: mean((vessel where (each.vlength = "VL2440")) collect each.grp_day);
            }
            }
         
        display grp_plot {
            chart "Landing monthly" type: series {
                data "VL1218" value: median((vessel where (each.vlength = "VL1218")) collect each.landing_collected_monthly);
                data "VL1824" value: median((vessel where (each.vlength = "VL1824")) collect each.landing_collected_monthly);
                data "VL2440" value: median((vessel where (each.vlength = "VL2440")) collect each.landing_collected_monthly);
            }
            }    
            
        } 
}