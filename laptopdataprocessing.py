import numpy as np
import pandas as pd
import os
import csv
import random

# reference: dataset and data clean up -> https://www.kaggle.com/code/danielbethell/laptop-prices-prediction/notebook
filepath = ''
for dirname, _, filenames in os.walk('./data'):
    for filename in filenames:
        filepath = os.path.join(dirname, filename)

laptops = pd.read_csv(filepath, encoding='latin-1')
laptops = laptops.set_index('laptop_ID')

# data cleaning up
laptops["Ram"] = laptops["Ram"].str.replace('GB', '')
laptops["Weight"] = laptops["Weight"].str.replace('kg', '')
laptops['Memory'] = laptops['Memory'].astype(str).replace('\.0', '', regex=True)
laptops["Memory"] = laptops["Memory"].str.replace('GB', '')
laptops["Memory"] = laptops["Memory"].str.replace('TB', '000')
new2 = laptops["Memory"].str.split("+", n = 1, expand = True)
laptops["first"]= new2[0]
laptops["first"]=laptops["first"].str.strip()
laptops["second"]= new2[1]
laptops["Layer1HDD"] = laptops["first"].apply(lambda x: 1 if "HDD" in x else 0)
laptops["Layer1SSD"] = laptops["first"].apply(lambda x: 1 if "SSD" in x else 0)
laptops["Layer1Hybrid"] = laptops["first"].apply(lambda x: 1 if "Hybrid" in x else 0)
laptops["Layer1Flash_Storage"] = laptops["first"].apply(lambda x: 1 if "Flash Storage" in x else 0)
laptops['first'] = laptops['first'].str.replace(r'\D', '')
laptops["second"].fillna("0", inplace = True)
laptops["Layer2HDD"] = laptops["second"].apply(lambda x: 1 if "HDD" in x else 0)
laptops["Layer2SSD"] = laptops["second"].apply(lambda x: 1 if "SSD" in x else 0)
laptops["Layer2Hybrid"] = laptops["second"].apply(lambda x: 1 if "Hybrid" in x else 0)
laptops["Layer2Flash_Storage"] = laptops["second"].apply(lambda x: 1 if "Flash Storage" in x else 0)
laptops['second'] = laptops['second'].str.replace(r'\D', '')
laptops["first"] = laptops["first"].astype(int)
laptops["second"] = laptops["second"].astype(int)
laptops["Total_Memory"]=(laptops["first"]*(laptops["Layer1HDD"]+laptops["Layer1SSD"]+laptops["Layer1Hybrid"]+laptops["Layer1Flash_Storage"])+laptops["second"]*(laptops["Layer2HDD"]+laptops["Layer2SSD"]+laptops["Layer2Hybrid"]+laptops["Layer2Flash_Storage"]))
laptops["Memory"]=laptops["Total_Memory"]
laptops["HDD"]=(laptops["first"]*laptops["Layer1HDD"]+laptops["second"]*laptops["Layer2HDD"])
laptops["SSD"]=(laptops["first"]*laptops["Layer1SSD"]+laptops["second"]*laptops["Layer2SSD"])
laptops["Hybrid"]=(laptops["first"]*laptops["Layer1Hybrid"]+laptops["second"]*laptops["Layer2Hybrid"])
laptops["Flash_Storage"]=(laptops["first"]*laptops["Layer1Flash_Storage"]+laptops["second"]*laptops["Layer2Flash_Storage"])
new = laptops["ScreenResolution"].str.split("x", n = 1, expand = True) 
laptops["X_res"]= new[0]
laptops["Y_res"]= new[1]
laptops["Y_res"]= pd.to_numeric(laptops["Y_res"])
laptops["Y_res"]= laptops["Y_res"].astype(float)
laptops["X_res"]=(laptops['X_res'].str.replace(',','').str.findall(r'(\d+\.?\d+)').apply(lambda x: pd.Series(x).astype(int)).mean(1))
laptops["X_res"]=pd.to_numeric(laptops["X_res"])
laptops["PPI"]=(((laptops["X_res"]**2+laptops["Y_res"]**2)**(1/2))/laptops["Inches"]).astype(float)
laptops["ScreenResolution"]=(laptops["X_res"]*laptops["Y_res"]).astype(float)
laptops["Ram"] = laptops["Ram"].astype(int)
laptops["Weight"] = laptops["Weight"].astype(float)
laptops=laptops.drop(['first','second','Layer1HDD','Layer1SSD','Layer1Hybrid','Layer1Flash_Storage','Layer2HDD','Layer2SSD','Layer2Hybrid','Layer2Flash_Storage','Total_Memory'],axis=1)


manufacturers = {}
manufacturer_id = 1
for company in laptops.Company.values.tolist():
    if company not in manufacturers:
        manufacturers[company] = manufacturer_id
        manufacturer_id += 1

electronics = laptops[['Company', 'Product', 'OpSys', 'Price_euros']].values.tolist();
osinstalled = []


csv_columns = ['ManufacturerID', 'ManufacturerName']
csv_file = "manufacturers.csv"
try:
    with open(csv_file, 'w') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=csv_columns)
        writer.writeheader()
        for m in manufacturers:
            writer.writerow({'ManufacturerID': manufacturers[m], 'ManufacturerName': m})
except IOError:
    print("I/O error")

e_csv_columns = ['ElectronicID', 'ElectronicName', 'ReleaseYear', 'Count', 'TotalCount', 'Rating', 'ManufacturerID', 'TypeID']
e_csv_file = "electronics.csv"
try:
    with open(e_csv_file, 'w') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=e_csv_columns)
        writer.writeheader()
        laptop_ID = 0
        for electronic in electronics:
            laptop_ID += 1
            opsys = electronic[2]
            opcode = 4 #'NO OS'
            if opsys == 'macOS' or opsys == 'Mac OS X':
                opcode = 3
            elif opsys == 'Windows 10':
                opcode = 1
            elif opsys == 'Linux':
                opcode = 2
            osinstalled.append({'ElectronicID': laptop_ID, 'OperatingSystemID': opcode})
            total_count = random.randint(3, 15)
            writer.writerow({'ElectronicID': laptop_ID, 'ElectronicName': electronic[1], 'ReleaseYear': random.randint(2019, 2022), 'Count': total_count, 
            'TotalCount': total_count, 'Rating': 'AVERAGE', 'ManufacturerID': manufacturers[electronic[0]], 'TypeID': 1})
except IOError:
    print("I/O error")

op_csv_columns = ['ElectronicID', 'OperatingSystemID']
op_csv_file = "osinstalled.csv"
try:
    with open(op_csv_file, 'w') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=op_csv_columns)
        writer.writeheader()
        for o in osinstalled:
            writer.writerow(o)
except IOError:
    print("I/O error")

print("Saved the data into CSV files")