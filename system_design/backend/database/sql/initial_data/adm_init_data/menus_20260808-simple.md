# Get menus list:
```sql
SELECT sort_order ,access_key ,name,locale  FROM menus
ORDER BY menus.sort_order::varchar ;
```

|sort_order|access_key|name|locale|
|----------|----------|----|------|
|10|ADM|Admin|menu.adm|
|1010|ADM001|Tenants|menu.adm.tenants|
|1020|ADM002|Options|menu.adm.options|
|1030|ADM003|Menus|menu.adm.menus|
|1040|ADM004|Permissions|menu.adm.permissions|
|1050|ADM005|Users|menu.adm.users|
|1060|ADM006|Roles|menu.adm.roles|
|20|BASIS|Basis|menu.basis|
|2010|BASIS001|Companies|menu.basis.companies|
|2020|BASIS002|Factories|menu.basis.factories|
|2030|BASIS003|Departments|menu.basis.departments|
|30|MM|Material|menu.mm|
|3010|MM01|Material categories|menu.mm.materialCategories|
|3020|MM02|Material types|menu.mm.materialTypes|
|3030|MM03|Material units|menu.mm.materialUnits|
|3040|MM04|Product models|menu.mm.productModels|
|3050|MM05|Product sizes|menu.mm.productSizes|
|3060|MM06|Colors|menu.mm.colors|
|3070|MM07|Materials|menu.mm.materials|
|3080|MM08|Standard unit conversions|menu.mm.standardUnitConversions|
|3090|MM09|Material unit conversions|menu.mm.materialUnitConversions|
|3095|MM10|Material Factories|menu.mm.materialFactories|
|40|SD|Sales and distribution|menu.sd|
|4010|SD01|Customer management|menu.sd.customers|
|4020|SD02|Sales orders(SO)|menu.sd.salesOrders|
|4030|SD03|Delivery Notes(DN)|menu.sd.deliveries|
|50|PP|Production planning|menu.pp|
|5010|PP01|Bill of materials(BOM)|menu.pp.billOfMaterials|
|5020|PP02|Factory orders(FO)|menu.pp.factoryOrders|
|5030|PP03|MRP Parameters|menu.pp.mrpParameters|
|5035|PP03S|MRP Schedules|menu.pp.mrpSchedules|
|5040|PP04|MRP Runs|menu.pp.mrpRuns|
|5050|PP05|Planned Orders(PLO)|menu.pp.plannedOrders|
|5060|PP06|Manufacturing Orders(MO)|menu.pp.productionOrders|
|5070|PP07|Manufacturing reports(MR)|menu.pp.productionReports|
|5080|PP08|Backflush Exception Queue|menu.pp.backflushExceptions|
|60|SCM|Purchase Management|menu.scm|
|6010|SCM01|Suppliers|menu.scm.suppliers|
|6020|SCM02|Purchase Requisitions(PR)|menu.scm.purchaseRequisitions|
|6030|SCM03|Purchase Order(PO)|menu.scm.purchaseOrders|
|6040|SCM04|Outsource Orders(OO)|menu.scm.outsourceOrders|
|70|WM|Warehouse Management|menu.wm|
|7010|WM01|Warehouse|menu.wm.warehouses|
|7020|WM02|Goods receipts(GR)|menu.wm.goodsReceipts|
|7030|WM03|Stock transfer(ST)|menu.wm.stockTransfers|
|7040|WM04|Stock issues(SI)|menu.wm.stockIssues|
|7045|WM04R|Stock issue returns(SIR)|menu.wm.stockIssueReturns|
|7050|WM05|Stock onhand|menu.wm.stockOnHand|
|7060|WM06|Stock transaction|menu.wm.stockTransactions|
|7070|WM07|Physical inventories|menu.wm.physicalInventories|
|7080|WM08|Inventory Balance|menu.wm.inventoryBalances|
|7090|WM09|Inventory Period|menu.wm.inventoryPeriods|
|80|FI|Financial Accounting|menu.fi|
|8010|FI.MD|Master Data|menu.fi.masterData|
|801010|FI1010|General Ledger Accounts|menu.fi.glAccounts|
|801020|FI1020|Business Partners|menu.fi.businessPartners|
|801030|FI1030|Company Bank Accounts|menu.fi.companyBankAccounts|
|801040|FI1040|Partner Bank Accounts|menu.fi.partnerBankAccounts|
|8020|FI.GL|General Ledger|menu.fi.generalLedger|
|802010|FI2010|Journal Entries|menu.fi.journalEntries|
|802020|FI2020|Fiscal Period Closing|menu.fi.fiscalPeriods|
|8030|FI.ARAP|AR & AP|menu.fi.arAp|
|803010|FI3010|AR Invoices|menu.fi.arInvoices|
|803020|FI3020|AP Invoices|menu.fi.apInvoices|
|803030|FI3030|Payments|menu.fi.payments|
|803040|FI3040|GR/IR Balance Analysis|menu.fi.grIrBalance|
|8040|FI.FA|Fixed Assets Management|menu.fi.fixedAssetMgmt|
|804010|FI4010|Asset Categories|menu.fi.assetCategories|
|804020|FI4020|Fixed Assets|menu.fi.fixedAssets|
|804030|FI4030|Asset Depreciation|menu.fi.assetDepreciations|
|8050|FI.VAL|Valuation|menu.fi.valuation|
|805010|FI5010|Valuation Classes|menu.fi.valuationClasses|
|805020|FI5020|Material Type & Valuation Class|menu.fi.materialTypeValuationClasses|
|805030|FI5030|Automatic Account Determination|menu.fi.accountDeterminations|
|8060|FI.CO|Product Costing|menu.fi.costing|
|806010|FI6010|Cost Roll-up|menu.fi.costCalculations|
|806020|FI6020|Material Cost|menu.fi.materialCosts|
|806030|FI6030|Costing Policies|menu.fi.costingPolicies|
|806040|FI6040|Cost Allocations|menu.fi.costAllocations|
|806050|FI6050|Purchase Cost Analysis|menu.fi.purchaseCostAnalysis|
|90|RPT|Report Center|menu.report|
|9010|RPT01|Export Jobs|menu.report.exportJobs|
|9020|RPT02|Import Center|menu.report.importJobs|
