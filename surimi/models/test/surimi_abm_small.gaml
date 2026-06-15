/**
* Name: surimi
* Based on the internal empty template. 
* Author: LENOVO
*/
model surimi

global {
    file shape_file_grid <- shape_file("../includes/smart5km/IBM_grid5km.shp");
 //   file shape_file_harbs <- shape_file("../includes/delete_SMART_Data/harbs_df_sf.shp");
 //   file shape_file_aggr <- shape_file("../includes/delete_SMART_Data/IBM.agg.grid_RP.shp");

    geometry shape <- envelope(shape_file_grid);
    map cell_by_idgrid <- map([]);
    map first_idgrid_of_cfr <- map([]);
    map vessel_info_by_cfr <- map([]);

 init {
    create cell from: shape_file_grid with:[
    	id_grid:string(read("id_grid")),
    	depth:int(read("depth")),
    	
    	MUT_W_mean:float(read("MUT_W_mean")), 
    	OCC_W_mean:float(read("OCC_W_mean")), 
    	HOM_W_mean:float(read("HOM_W_mean")), 
    	RJC_W_mean:float(read("RJC_W_mean")), 
    	EDT_W_mean:float(read("EDT_W_mean")), 
    	HKE_W_mean:float(read("HKE_W_mean")), 
    	RJO_W_mean:float(read("RJO_W_mean")), 
    	MON_W_mean:float(read("MON_W_mean")), 
    	MTS_W_mean:float(read("MTS_W_mean")), 
    	MUR_W_mean:float(read("MUR_W_mean")), 
    	EOI_W_mean:float(read("EOI_W_mean")), 
    	SQM_W_mean:float(read("SQM_W_mean")), 
    	DPS_W_mean:float(read("DPS_W_mean")), 
    	SDV_W_mean:float(read("SDV_W_mean")), 
    	JRS_W_mean:float(read("JRS_W_mean")), 
    	SYC_W_mean:float(read("SYC_W_mean")), 
    	JAI_W_mean:float(read("JAI_W_mean")), 
    	CTC_W_mean:float(read("CTC_W_mean")), 
    	ARS_W_mean:float(read("ARS_W_mean")), 
    	NEP_W_mean:float(read("NEP_W_mean")), 
    	ARA_W_mean:float(read("ARA_W_mean")), 
    	QUB_W_mean:float(read("QUB_W_mean"))
    	
    	
    ];
    
    ask cell {
    cell_by_idgrid[id_grid] <- self;
}
    
//    first_cell_of_cfr <- map([]);
    
    create harbour from: shape_file_harbs with:[
    	name::string(read("HARBOUR")), 
    	nvessel::int(read("NVESSEL"))
    ];
    
    
//    ask cell {
//    if (CFR != "" and !(first_cell_of_cfr contains_key CFR)) {
//        first_cell_of_cfr[CFR] <- self;
//    }
//}

//create vessel from: shape_file_aggr with: [
//    CFR:: string(read("CFR")),
//    id_grid:: string(read("id_grid"))
//];

create aggr_row from: shape_file_aggr with: [
    CFR:: string(read("CFR")),
    id_grid:: string(read("id_grid")),
    gear:: string(read("Gear"))
];
first_idgrid_of_cfr <- map([]);
vessel_info_by_cfr <- map([]);

ask aggr_row {
    if (CFR != "" and !(first_idgrid_of_cfr contains_key CFR)) {
        vessel_info_by_cfr[CFR] <- ["id_grid":: id_grid, "gear":: gear];
    }

}

loop cfr over: keys(vessel_info_by_cfr) {

    create vessel {
        CFR <- string(cfr);
        map info <- vessel_info_by_cfr[cfr];
        id_grid <- string(info["id_grid"]);
        gear <- string(info["gear"]);

        if (cell_by_idgrid contains_key id_grid) {
            cell c <- cell_by_idgrid[id_grid];
            location <- c.location; // visible + consistent
            // optional jitter to avoid overlap:
            // location <- location + { rnd(-10,10), rnd(-10,10) };
        } else {
            location <- any_location_in(shape);
             write "No matching cell for CFR=" + CFR + " id_grid=" + id_grid;
        }
    }
}

write "aggr rows=" + string(length(aggr_row)) + " | unique vessels=" + string(length(vessel));

//ask vessel {
//    if (cell_by_idgrid contains_key id_grid) {
//        cell c <- cell_by_idgrid[id_grid];
//        location <- c.location;   // guaranteed visible
//        // optional jitter to avoid overlap:
//        //location <- location + { rnd(-10, 10), rnd(-10, 10) };
//    } else {
//        location <- any_location_in(shape);
//        write "No matching cell for vessel CFR=" + CFR + " id_grid=" + id_grid;
//    }
//}
}
}    

species cell {
	string id_grid <- "";
	int depth <- 0;
	int MUT_W_mean <- MUT_W_mean;
    int OCC_W_mean <- OCC_W_mean;
    int HOM_W_mean <- HOM_W_mean;
    int RJC_W_mean <-  RJC_W_mean;
    int EDT_W_mean <-  EDT_W_mean; 
    int HKE_W_mean <-  HKE_W_mean; 
    int RJO_W_mean <-  RJO_W_mean;
    int MON_W_mean <-  MON_W_mean;
    int MTS_W_mean <-  MTS_W_mean;
    int MUR_W_mean <-  MUR_W_mean;
    int EOI_W_mean <-  EOI_W_mean;
    int SQM_W_mean <-  SQM_W_mean;
    int DPS_W_mean <-  DPS_W_mean;
    int SDV_W_mean <-  SDV_W_mean;
    int JRS_W_mean <-  JRS_W_mean;
    int SYC_W_mean <-  SYC_W_mean;
    int JAI_W_mean <-  JAI_W_mean;
    int CTC_W_mean <-  CTC_W_mean;
    int ARS_W_mean <-  ARS_W_mean;
    int NEP_W_mean <-  NEP_W_mean;
    int ARA_W_mean <-  ARA_W_mean;
    int QUB_W_mean <-  QUB_W_mean;
    aspect base {
//        draw shape color: #blue border: #black width: 1;
    draw shape color: #blue  border: #black width: 1;
	
    }
}

species harbour {
	string name <- "";
	int nvessel <- 0;
    aspect base {
//        draw shape color: #blue border: #black width: 1;
	draw circle(5000) color: #red border: #black;

    }
}

species vessel{
	string CFR <- "";
	string id_grid <- "";
	string gear <- "";
	aspect base{
		draw triangle(5000) color: #green border: #black rotate: 180;
		
	}
}

species aggr_row {
    string CFR <- "";
    string id_grid <- "";
    string gear <- "";
}

experiment surimi type: gui {

	output {
		display landscape type:2d {
			species cell aspect: base ;
			species harbour aspect: base;
			species vessel aspect: base;

		}
	}

}