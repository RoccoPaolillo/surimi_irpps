
README — EU DCF AER Economic (2013-2023)
===================================================================

Title
-----
AER Economic by fleet segment and national level 2013-2023.


Summary
-------
The 2024 Annual Economic Report (AER) on the European Union (EU) fishing fleet provides a comprehensive overview of the latest information available on the structure and economic performance of EU Member State fishing fleets. This report covers the period 2008 to 2022 and includes information on the EU fleet’s fishing capacity, effort, employment, landings, income and costs. The reference year is 2022 with nowcast performance estimates provided for 2023 and 2024, where possible. All monetary values have been adjusted for inflation to 2022 constant prices. The profitability and performance of the EU fishing fleet are also reported in terms of Gross Value Added (GVA), profits (gross and net), profit margins, resource productivity (labour and capital) and efficiency (fuel use, LPUE, etc.).
Specifically, the data include:
Effort (Fishing days, Days at sea, kW fishing days, GT fishing days, Maximum days at sea, Number of fishing trips, Energy consumption) 
Capital (Total assets, Gross debt, Investments, Value of physical capital, Value of quota and other fishing rights, Subsidies on investments)
Expenditure (Consumption of fixed capital, Other variable costs, Other non-variable costs, Lease/rental payments for quota, Repair & maintenance costs, Energy costs, Personnel costs, Value of unpaid labour
Income (Operating subsidies, Gross value of landings, Income from leasing out quota, Other income, 
Employment (Engaged crew, Total hours worked per year, Unpaid labour, FTE national

Provenance
---------------
- Data source: AER data
  Downloaded from AER | https://datacollection.jrc.ec.europa.eu

Temporal & Spatial Coverage
---------------------------
- Years: 2013-2023.
- Area: European Member State.

Methodology (Processing Overview)
---------------------------------
1) Acquisition: Download the effort 2013-2023 dataset from AER.
2) Harmonisation:
   - Geographic attributes  as FAO Area/Subarea/Division and names.
   - Add description columns for Fishing tech, Geographic indicator.	


Schema 
-------------------
Columns :

country_name: The name of the country where the data was collected.
country_code: The standardized code for the country (e.g., ISO 3166-1 alpha-3).
year: The year of data collection or reference.
supra_reg: The supranational region grouping from FAO.
fishing_tech: A coded classification of the fishing technique used (e.g., trawling, longlining, purse seine).
vessel_length: The length category of fishing vessels used (e.g., <12m, 12–24m, >24m).
geo_indicator: A coded geographic indicator for the fishing activity location.
cluster_name: aggregation of fleet segment due to sampling purposes or confidentiality
fs_name: fleet segment name
variable_group: Effort, Capital, Expenditure, Income, Employment 
variable_name: sub category of variable group
variable_code
value: value of variable name
unit: unit of the value
gear: Gear type
activity: The activity level indicator, denoted as follows: L = Low active; A = Active (normal and high). It isa used to provide an additional subordinate level of fleet definition according to the individual vessel activity characteristics where necessary. This approach enables the separate analysis the economic performance of the subsegments of vessels with low activity and those with normal and high activity
fishing_tech_desc: Description of fishing technique
geo_indicator_desc: Description of Geographic indicator

Citation

Scientific Technical and Economic Committee for Fisheries (STECF) – The 2024 Annual Economic Report on the EU Fishing Fleet (STECF-24-03 & STECF-24-07), Prellezo, R., Sabatella, E.C., Virtanen, J., Tardy Martorell, M., and Guillen, J. editor(s), Publications Office of the European Union, Luxembourg, 2024, https://data.europa.eu/doi/10.2760/5037826, JRC139642.
