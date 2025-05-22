
public with sharing class DashboardExportController {
    /**
     * Get all components available in a dashboard
     * @param dashboardId The ID of the dashboard
     * @return List of component names
     */
    @AuraEnabled
    public static List<String> getDashboardComponents(Id dashboardId) {
        List<String> componentNames = new List<String>();
           
            // Query for dashboard components
            // First, attempt to get components directly from the Dashboard
            try {
                // Query for dashboard components - direct method if available in your API version
                Dashboard dashboard = [SELECT Id, (SELECT Id, Name FROM DashboardComponents) 
                                      FROM Dashboard WHERE Id = :dashboardId LIMIT 1];
                
                for (DashboardComponent component : dashboard.DashboardComponents) {
                    componentNames.add(component.Name);
                }
            } 
            catch (Exception e) {
                System.debug('Error querying dashboard components directly: ' + e.getMessage());
                
                // Alternative approach: query reports in the org and try to identify which ones
                // might be used in dashboards by naming conventions or last usage
                List<Report> recentReports = [
                    SELECT Id, Name
                    FROM Report
                    WHERE LastRunDate != null
                    ORDER BY LastRunDate DESC
                    LIMIT 50
                ];
                
                for (Report report : recentReports) {
                    if (!componentNames.contains(report.Name)) {
                        componentNames.add(report.Name);
                    }
                }
            }
            
            // Sort the component names alphabetically
            componentNames.sort();
            
            return componentNames;
    }


        /**
     * Find reports by name
     * @param reportName The name of the report to search for
     * @return Set of report IDs matching the name
     */
    @TestVisible
    private static Set<Id> findReportsByName(String reportName) {
        Set<Id> reportIds = new Set<Id>();
        
        if (String.isBlank(reportName)) {
            return reportIds;
        }
        
        // try {
            // Query for reports with exact name match
            List<Report> reports = [
                SELECT Id, Name
                FROM Report
                WHERE Name = :reportName
                LIMIT 10
            ];
            
            for (Report report : reports) {
                reportIds.add(report.Id);
            }
            
            System.debug('Found ' + reportIds.size() + ' reports with exact name: ' + reportName);
        // } 
        // catch (Exception e) {
        //     System.debug('Error in findReportsByName: ' + e.getMessage());
        // }
        
        return reportIds;
    }

    /**
     * Get the name of a report by its ID
     * @param reportId The ID of the report
     * @return The name of the report
     */
    @TestVisible
    private static String getReportName(Id reportId) {
        String reportName = 'Unknown Report';
        
        if (reportId == null) {
            return reportName;
        }
        
        try {
            Report report = [SELECT Id, Name FROM Report WHERE Id = :reportId LIMIT 1];
            if (report != null) {
                reportName = report.Name;
            }
        } catch (Exception e) {
            System.debug('Error in getReportName: ' + e.getMessage());
        }
        
        return reportName;
    }

    /**
     * Find reports using broader search criteria when exact match fails
     * @param searchTerm The search term for report name
     * @return Set of report IDs that match the broader search
     */
    @TestVisible
    private static Set<Id> findReportsByBroaderSearch(String searchTerm) {
        Set<Id> reportIds = new Set<Id>();
        
        if (String.isBlank(searchTerm)) {
            return reportIds;
        }
        
        try {
            // First try with LIKE operator
            String likePattern = '%' + searchTerm + '%';
            List<Report> reports = [
                SELECT Id, Name
                FROM Report
                WHERE Name LIKE :likePattern
                ORDER BY LastRunDate DESC NULLS LAST
                LIMIT 10
            ];
            
            for (Report report : reports) {
                reportIds.add(report.Id);
            }
            
            System.debug('Found ' + reportIds.size() + ' reports with LIKE search: ' + searchTerm);
            
            // If no results, try with keywords
            if (reportIds.isEmpty()) {
                // Split the search term into keywords
                List<String> keywords = searchTerm.split('\\s+');
                for (String keyword : keywords) {
                    if (keyword.length() > 3) { // Only search for meaningful keywords
                        String keywordPattern = '%' + keyword + '%';
                        List<Report> keywordReports = [
                            SELECT Id, Name
                            FROM Report
                            WHERE Name LIKE :keywordPattern
                            ORDER BY LastRunDate DESC NULLS LAST
                            LIMIT 5
                        ];
                        
                        for (Report report : keywordReports) {
                            reportIds.add(report.Id);
                        }
                    }
                }
                
                System.debug('Found ' + reportIds.size() + ' reports with keyword search');
            }
        } catch (Exception e) {
            System.debug('Error in findReportsByBroaderSearch: ' + e.getMessage());
        }
        
        return reportIds;
    }


    /**
     * Exports data from reports associated with dashboard components
     * @param dashboardId The ID of the dashboard
     * @param componentName Optional name of the specific component to export
     * @return Map of report names to their data records
     */
    @AuraEnabled
    public static Map<String, List<Map<String, Object>>> exportDashboardData(Id dashboardId, String componentName) {
        dashboardId='01ZNS000003BIG12AO';
        // if (dashboardId == null) {
        //     throw new AuraHandledException('Dashboard ID cannot be null');
        // }
        // if (Test.isRunningTest()) {
        //     return getTestDashboardData(dashboardId, componentName);
        // }
        // try {
        //     System.debug('Starting export with dashboardId: ' + dashboardId + ', componentName: ' + componentName);
           
            Map<String, List<Map<String, Object>>> reportData = new Map<String, List<Map<String, Object>>>();
           
            if (String.isNotBlank(componentName) && componentName != 'All Components') {
                // If a specific component is requested, find its report by name
                Set<Id> reportIds = findReportsByName(componentName);
                
                // System.debug('Found ' + reportIds.size() + ' report IDs for component: ' + componentName);
                
                // Process the specific report
                // if (!reportIds.isEmpty()) {
                //     for (Id reportId : reportIds) {
                //         String reportName = getReportName(reportId);
                //         List<Map<String, Object>> singleReportData = exportReportData(reportId);
                        
                //         // Only add non-empty report data
                //         if (singleReportData != null && !singleReportData.isEmpty()) {
                //             // Add report name to each record
                //             for (Map<String, Object> record : singleReportData) {
                //                 record.put('Report_Source', reportName);
                //             }
                            
                //             reportData.put(reportName, singleReportData);
                //         }
                //     }
                // } 
                
                // else {
                    // Try a more lenient search if we didn't find an exact match
                    reportIds = findReportsByBroaderSearch(componentName);
                    
                    for (Id reportId : reportIds) {
                        String reportName = getReportName(reportId);
                        List<Map<String, Object>> singleReportData = exportReportData(reportId);
                        
                        // Only add non-empty report data
                        if (singleReportData != null && !singleReportData.isEmpty()) {
                            // Add report name to each record
                            for (Map<String, Object> record : singleReportData) {
                                record.put('Report_Source', reportName);
                            }
                            
                            reportData.put(reportName, singleReportData);
                        }
                    }
                // }
            } else {
                // Process all reports that might be related to the dashboard
                List<Report> allReports;
                
                // try {
                    // Try to get all recently used reports
                    allReports = [
                        SELECT Id, Name
                        FROM Report
                        WHERE LastRunDate != null
                        ORDER BY LastRunDate DESC
                        LIMIT 50
                    ];
                // } catch (Exception e) {
                //     // Fallback to recent reports by created date
                //     allReports = [
                //         SELECT Id, Name
                //         FROM Report
                //         ORDER BY CreatedDate DESC
                //         LIMIT 50
                //     ];
                // }
                
                System.debug('Found ' + allReports.size() + ' reports for "All Components" option');
                
                // Process each report
                for (Report report : allReports) {
                    Id reportId = report.Id;
                    String reportName = report.Name;
                    
                    // try {
                        List<Map<String, Object>> reportDataItems = exportReportData(reportId);
                        
                        // Only add non-empty report data
                        if (reportDataItems != null && !reportDataItems.isEmpty()) {
                            // Add report name to each record
                            for (Map<String, Object> record : reportDataItems) {
                                record.put('Report_Source', reportName);
                            }
                            
                            reportData.put(reportName, reportDataItems);
                        }
                    // } 
                    // catch (Exception e) {
                    //     System.debug('Error processing report: ' + reportName + ', Error: ' + e.getMessage());
                    //     // Continue with other reports
                    }
                }
            
           
            // If we still don't have reports, provide a helpful error
            // if (reportData.isEmpty()) {
            //     throw new AuraHandledException('No reports found for the specified criteria. Please ensure the reports exist and are accessible.');
            // }
        // }
            return reportData;
        // } 
        // catch (Exception e) {
        //     System.debug('Exception in exportDashboardData: ' + e.getMessage() + '\n' + e.getStackTraceString());
        //     throw new AuraHandledException('Error retrieving dashboard data: ' + e.getMessage());
        // }
    }
   
/**
 * Enhanced method to extract data from different report formats
 * This method can replace your existing exportReportData method for better handling of different report types
 */
    @AuraEnabled
    public static List<Map<String, Object>> exportReportData(Id reportId) {
        // if (Test.isRunningTest()) {
        //     return getTestReportData(reportId);
        // }

        List<Map<String, Object>> exportData = new List<Map<String, Object>>();
        
        try {
            System.debug('Running report: ' + reportId);
            
            // Get the report details
            Reports.ReportResults results = Reports.ReportManager.runReport(reportId, true);
            Reports.ReportMetadata metadata = results.getReportMetadata();
            Reports.ReportFormat reportFormat = metadata.getReportFormat();
            
            System.debug('Report format: ' + reportFormat);
            
            // Specific handling for specialized reports - detect by name
            String reportName = getReportName(reportId);
            if (reportName.contains('Fair Participation')) {
                System.debug('Using specialized handling for Fair Participation Report');
                return processSpecialReport(results, metadata);
            }
            
            // Get all factMap keys to handle different report formats
            Set<String> factMapKeys = results.getFactMap().keySet();
            System.debug('Available factMap keys: ' + factMapKeys);
            
            // if (factMapKeys.isEmpty()) {
            //     System.debug('No data available in the report');
            //     Map<String, Object> noDataRecord = new Map<String, Object>();
            //     noDataRecord.put('Info', 'No data available in the report');
            //     exportData.add(noDataRecord);
            //     return exportData;
            // }
            
            // Process based on report format - using safer checks instead of enum values
            String formatName = String.valueOf(reportFormat);
            
            if (formatName == 'TABULAR') {
                System.debug('Processing tabular report');
                // // For tabular reports, T!T is the key
                // if (factMapKeys.contains('T!T')) {
                //     exportData = processReportFactWithDetails(results, metadata, 'T!T');
                // }
            }
            else if (formatName == 'SUMMARY') {
                System.debug('Processing summary report');
                // For summary reports, need to handle multiple levels of grouping
                exportData = processSummaryReport(results, metadata, factMapKeys);
            }
            // else if (formatName == 'MATRIX') {
            //     System.debug('Processing matrix report');
            //     // For matrix reports, complex grid of data
            //     exportData = processMatrixReport(results, metadata, factMapKeys);
            // }
            // // Instead of directly checking for JOINED, we'll use a string comparison
            // else if (formatName.equals('JOINED')) {
            //     System.debug('Processing joined report');
            //     // For joined reports, which combine multiple report blocks
            //     exportData = processJoinedReport(results, metadata, factMapKeys);
            // }
            else {
                System.debug('Unknown report format: ' + formatName);
                // Generic approach for any format
                String bestKey = determineMainFactMapKey(factMapKeys);
                
                // if (bestKey != null) {
                //     System.debug('Using best key: ' + bestKey);
                //     Object factObject = results.getFactMap().get(bestKey);
                    
                //     if (factObject instanceof Reports.ReportFactWithDetails) {
                //         exportData = processReportFactWithDetails(results, metadata, bestKey);
                //     } else if (factObject instanceof Reports.ReportFactWithSummaries) {
                //         exportData = processReportFactWithSummaries(results, metadata, bestKey);
                //     }
                // }
            }
            
            // If we still don't have data, try a more aggressive approach
            if (exportData.isEmpty()) {
                System.debug('No data found with format-specific approach, trying all keys');
                
                for (String key : factMapKeys) {
                    List<Map<String, Object>> keyData = new List<Map<String, Object>>();
                    Object factObject = results.getFactMap().get(key);
                    
                    if (factObject instanceof Reports.ReportFactWithDetails) {
                        keyData = processReportFactWithDetails(results, metadata, key);
                    } else if (factObject instanceof Reports.ReportFactWithSummaries) {
                        keyData = processReportFactWithSummaries(results, metadata, key);
                    }
                    
                    if (!keyData.isEmpty()) {
                        // Add a marker to show which key this data came from
                        for (Map<String, Object> record : keyData) {
                            record.put('FactMap_Key', key);
                        }
                        exportData.addAll(keyData);
                    }
                }
            }
            
            // If we still have no data, provide diagnostic information
            if (exportData.isEmpty()) {
                Map<String, Object> diagnosticData = new Map<String, Object>();
                diagnosticData.put('Info', 'No data could be extracted from the report');
                diagnosticData.put('Report_Format', String.valueOf(reportFormat));
                diagnosticData.put('Report_Name', reportName);
                diagnosticData.put('Available_Keys', String.join(new List<String>(factMapKeys), ', '));
                exportData.add(diagnosticData);
            }
            
            System.debug('Exported ' + exportData.size() + ' records');
            return exportData;
        } catch (Exception e) {
            System.debug('Error in exportReportData: ' + e.getMessage() + '\n' + e.getStackTraceString());
            
            // Return a record with the error message
            Map<String, Object> errorData = new Map<String, Object>();
            errorData.put('Error', 'Failed to process report: ' + e.getMessage());
            exportData.add(errorData);
            return exportData;
        }
    }

    /**
     * Helper method to determine the most useful factMap key
     */
    @TestVisible
    private static String determineMainFactMapKey(Set<String> factMapKeys) {
        if (factMapKeys.isEmpty()) {
            return null;
        }
        
        // Priority order: T!T, grand total, other totals, detail rows
        if (factMapKeys.contains('T!T')) {
            return 'T!T';
        }
        
        // Look for summary keys (usually represent totals)
        for (String key : factMapKeys) {
            if (key.contains('!T')) {
                return key;
            }
        }
        
        // Default to first key
        return new List<String>(factMapKeys)[0];
    }

    /**
     * Process summary reports by handling grouping levels
     */
    @TestVisible
    private static List<Map<String, Object>> processSummaryReport(Reports.ReportResults results, 
                                                                Reports.ReportMetadata metadata,
                                                                Set<String> factMapKeys) {
        List<Map<String, Object>> exportData = new List<Map<String, Object>>();
        
        try {
            // Get grouping columns for better data structure
            List<Reports.GroupingInfo> groupingColumns = metadata.getGroupingsDown();
            System.debug('Number of grouping levels: ' + (groupingColumns != null ? groupingColumns.size() : 0));
            
            // Process each factMap key
            for (String key : factMapKeys) {
                System.debug('Processing summary key: ' + key);
                Object factObject = results.getFactMap().get(key);
                
                if (factObject instanceof Reports.ReportFactWithDetails) {
                    // Found detail rows - this is the data we want
                    List<Map<String, Object>> keyData = processReportFactWithDetails(results, metadata, key);
                    
                    if (!keyData.isEmpty()) {
                        // Try to extract grouping information from the key
                        if (key.contains('!')) {
                            String[] keyParts = key.split('!');
                            if (keyParts.size() > 1 && !keyParts[0].equals('T')) {
                                // This represents a specific group - add group info
                                Integer groupLevel = Integer.valueOf(keyParts[0]);
                                String groupValue = keyParts[1];
                                
                                // Add grouping information to each record
                                for (Map<String, Object> record : keyData) {
                                    record.put('Group_Level', groupLevel);
                                    record.put('Group_Value', groupValue);
                                    
                                    // Try to get the group column name if available
                                    if (groupingColumns != null && groupLevel < groupingColumns.size()) {
                                        Reports.GroupingInfo groupInfo = groupingColumns[groupLevel];
                                        String groupColumnName = String.valueOf(groupInfo.getName());
                                        record.put('Group_Column', groupColumnName);
                                    }
                                }
                            }
                        }
                        
                        exportData.addAll(keyData);
                    }
                } else if (factObject instanceof Reports.ReportFactWithSummaries) {
                    List<Map<String, Object>> summaryData = processReportFactWithSummaries(results, metadata, key);
                    
                    // if (!summaryData.isEmpty()) {
                    //     // Add the summary data
                    //     exportData.addAll(summaryData);
                    // }
                }
            }
            
            return exportData;
        } catch (Exception e) {
            System.debug('Error processing summary report: ' + e.getMessage());
            Map<String, Object> errorData = new Map<String, Object>();
            errorData.put('Error', 'Error processing summary report: ' + e.getMessage());
            exportData.add(errorData);
            return exportData;
        }
    }



/**
 * Process report data using a specific factMapKey
 */
    @TestVisible
    private static List<Map<String, Object>> processReportData(Reports.ReportResults results, 
                                                            Reports.ReportMetadata metadata,
                                                            String factMapKey) {
        List<Map<String, Object>> exportData = new List<Map<String, Object>>();
        
        try {
            Object factObject = results.getFactMap().get(factMapKey);
            
            // Process based on the type of factObject
            if (factObject instanceof Reports.ReportFactWithDetails) {
                return processReportFactWithDetails(results, metadata, factMapKey);
            } 
            else if (factObject instanceof Reports.ReportFactWithSummaries) {
                return processReportFactWithSummaries(results, metadata, factMapKey);
            }
            else {
                // Try a generic approach for unknown types
                System.debug('Unsupported fact object type for key: ' + factMapKey);
                Map<String, Object> typeData = new Map<String, Object>();
                typeData.put('Key', factMapKey);
                typeData.put('Info', 'Unsupported report data format');
                exportData.add(typeData);
            }
        } catch (Exception e) {
            System.debug('Error in processReportData for key ' + factMapKey + ': ' + e.getMessage());
            Map<String, Object> errorData = new Map<String, Object>();
            errorData.put('Key', factMapKey);
            errorData.put('Error', 'Error processing report data: ' + e.getMessage());
            exportData.add(errorData);
        }
        
        return exportData;
    }


    /**
     * Process reports with details (used for tabular reports)
     */
    @TestVisible
    private static List<Map<String, Object>> processReportFactWithDetails(Reports.ReportResults results,
                                                                        Reports.ReportMetadata metadata,
                                                                        String factMapKey) {
        List<Map<String, Object>> exportData = new List<Map<String, Object>>();
        
        try {
            Reports.ReportFactWithDetails factDetails = 
                (Reports.ReportFactWithDetails)results.getFactMap().get(factMapKey);
            
            // Process column headers and build a map of column names to labels
            Map<String, String> columnToLabelMap = new Map<String, String>();
            for (String columnName : metadata.getDetailColumns()) {
                String columnLabel = columnName; // Default to API name
                
                // Try to get the more user-friendly label
                try {
                    Reports.DetailColumn columnInfo = results.getReportExtendedMetadata().getDetailColumnInfo().get(columnName);
                    if (columnInfo != null) {
                        columnLabel = columnInfo.getLabel();
                    }
                } catch (Exception e) {
                    System.debug('Error getting column label for ' + columnName + ': ' + e.getMessage());
                }
                
                columnToLabelMap.put(columnName, columnLabel);
            }
            
            System.debug('Columns: ' + columnToLabelMap.size());
            
            // Process each row of data
            List<Reports.ReportDetailRow> rows = factDetails.getRows();
            System.debug('Rows: ' + (rows != null ? rows.size() : 0));
            
            if (rows != null && !rows.isEmpty()) {
                for (Reports.ReportDetailRow row : rows) {
                    Map<String, Object> rowData = new Map<String, Object>();
                    
                    // Process cells
                    List<Reports.ReportDataCell> cells = row.getDataCells();
                    
                    // Safety check for column and cell count mismatch
                    Integer columnCount = metadata.getDetailColumns().size();
                    Integer cellCount = cells.size();
                    
                    for (Integer i = 0; i < columnCount; i++) {
                        String columnName = metadata.getDetailColumns()[i];
                        String columnLabel = columnToLabelMap.get(columnName);
                        
                        // Get cell value with safety check
                        Object value = null;
                        if (i < cellCount) {
                            try {
                                value = cells[i].getValue();
                            } catch (Exception e) {
                                value = '[Error reading value]';
                            }
                        }
                        
                        rowData.put(columnLabel, value);
                    }
                    
                    exportData.add(rowData);
                }
            } else {
                Map<String, Object> emptyData = new Map<String, Object>();
                emptyData.put('Info', 'No data rows in report');
                emptyData.put('Key', factMapKey);
                exportData.add(emptyData);
            }
            
            return exportData;
        } catch (Exception e) {
            System.debug('Error in processReportFactWithDetails: ' + e.getMessage());
            Map<String, Object> errorData = new Map<String, Object>();
            errorData.put('Error', 'Error processing report details: ' + e.getMessage());
            errorData.put('Key', factMapKey);
            exportData.add(errorData);
            return exportData;
        }
    }



    
    
        /**
         * Process reports with summaries (used for summary and matrix reports)
         */
        @TestVisible
        private static List<Map<String, Object>> processReportFactWithSummaries(Reports.ReportResults results,
                                                                            Reports.ReportMetadata metadata,
                                                                            String factMapKey) {
            List<Map<String, Object>> exportData = new List<Map<String, Object>>();
            try {
                Reports.ReportFactWithSummaries factWithSummaries =
                    (Reports.ReportFactWithSummaries)results.getFactMap().get(factMapKey);
            
                // Get aggregates
                List<Reports.SummaryValue> aggregates = factWithSummaries.getAggregates();
            
                // Create a record with the aggregate data
                Map<String, Object> summaryRecord = new Map<String, Object>();
            
                // Add group info if available
                if (factMapKey.contains('!')) {
                    String[] keyParts = factMapKey.split('!');
                    if (keyParts.size() > 1) {
                        summaryRecord.put('Group_ID', factMapKey);
                    
                        // Try to extract group value labels
                        try {
                            // Get down groupings
                            List<Reports.GroupingInfo> groupingColumns = metadata.getGroupingsDown();
                            if (groupingColumns != null && !groupingColumns.isEmpty() && keyParts.size() >= 2) {
                                Integer groupLevel = keyParts[0].equals('T') ? 0 : Integer.valueOf(keyParts[0]);
                                if (groupLevel < groupingColumns.size()) {
                                    Reports.GroupingInfo groupInfo = groupingColumns[groupLevel];
                                    // Use a more basic approach - just store the name
                                    String groupName = String.valueOf(groupInfo);
                                    summaryRecord.put('Grouping_Column', groupName);
                                
                                    // Try to get the label for this group value
                                    if (!keyParts[1].equals('T')) {
                                        String groupValue = keyParts[1];
                                        summaryRecord.put('Group_Value', groupValue);
                                    }
                                }
                            }
                        } catch (Exception e) {
                            System.debug('Error extracting group info: ' + e.getMessage());
                        }
                    }
                }
            
                // Process aggregates
                if (aggregates != null && !aggregates.isEmpty()) {
                    List<String> metadataAggregates = new List<String>();
                
                    // Get aggregate names from metadata if available
                    try {
                        // Use a simpler approach - get whatever we can from aggregates
                        List<Object> aggregateInfos = metadata.getAggregates();
                        if (aggregateInfos != null) {
                            for (Integer i = 0; i < aggregateInfos.size(); i++) {
                                metadataAggregates.add('Aggregate_' + i);
                            }
                        }
                    } catch (Exception e) {
                        System.debug('Error getting aggregate names: ' + e.getMessage());
                    }
                
                    for (Integer i = 0; i < aggregates.size(); i++) {
                        String aggLabel = 'Aggregate_' + i;
                    
                        // Try to get a more friendly name from metadata
                        if (i < metadataAggregates.size()) {
                            aggLabel = metadataAggregates[i];
                            // Try to get even friendlier label
                            try {
                                Reports.AggregateColumn aggInfo =
                                    results.getReportExtendedMetadata().getAggregateColumnInfo().get(aggLabel);
                                if (aggInfo != null) {
                                    aggLabel = aggInfo.getLabel();
                                }
                            } catch (Exception e) {
                                // Use the default label
                            }
                        }
                    
                        summaryRecord.put(aggLabel, aggregates[i].getValue());
                    }
                }
            
                exportData.add(summaryRecord);
            
                // Try to process child groupings if available
                try {
                    // We'll skip trying to navigate through groupings automatically
                    // as the API methods might differ between API versions
                    // Instead, we'll make sure we at least capture the current level's data
                    System.debug('Not attempting to process nested groupings due to API compatibility');
                } catch (Exception e) {
                    System.debug('Error processing child groupings: ' + e.getMessage());
                }
            
                return exportData;
            } catch (Exception e) {
                System.debug('Error processing ReportFactWithSummaries: ' + e.getMessage());
                Map<String, Object> errorRecord = new Map<String, Object>();
                errorRecord.put('Error', 'Could not process summaries: ' + e.getMessage());
                exportData.add(errorRecord);
                return exportData;
            }
        }
   
    /**
     * Special processing for Fair Participation Report which has a different structure
     */
    @TestVisible
    private static List<Map<String, Object>> processSpecialReport(Reports.ReportResults results, Reports.ReportMetadata metadata) {
        List<Map<String, Object>> exportData = new List<Map<String, Object>>();
       
        try {
            System.debug('Processing special report format');
            System.debug('Report format: ' + metadata.getReportFormat());
           
            // Get all available fact map keys
            Set<String> availableKeys = results.getFactMap().keySet();
            System.debug('Available fact map keys: ' + availableKeys);
           
            // Process each key in the fact map individually
            for (String key : availableKeys) {
                System.debug('Processing key: ' + key);
                Object factObject = results.getFactMap().get(key);
               
                // Try to process based on the actual object type
                if (factObject instanceof Reports.ReportFactWithDetails) {
                    // It's a detailed report with rows
                    System.debug('Found ReportFactWithDetails for key: ' + key);
                    Reports.ReportFactWithDetails factDetails = (Reports.ReportFactWithDetails)factObject;
                   
                    // Get the column information
                    List<String> detailColumns = metadata.getDetailColumns();
                    Map<String, String> columnToLabelMap = new Map<String, String>();
                   
                    for (String columnName : detailColumns) {
                        String columnLabel = columnName;
                        // try {
                            if (results.getReportExtendedMetadata().getDetailColumnInfo().containsKey(columnName)) {
                                Reports.DetailColumn columnInfo =
                                    results.getReportExtendedMetadata().getDetailColumnInfo().get(columnName);
                                columnLabel = columnInfo.getLabel();
                            // }
                        } 
                        // catch (Exception e) {
                        //     System.debug('Error getting column label: ' + e.getMessage());
                        // }
                        columnToLabelMap.put(columnName, columnLabel);
                    }
                   
                    // Get the rows
                    List<Reports.ReportDetailRow> rows = factDetails.getRows();
                    if (rows != null && !rows.isEmpty()) {
                        for (Reports.ReportDetailRow row : rows) {
                            Map<String, Object> rowData = new Map<String, Object>();
                            rowData.put('GroupKey', key); // Add the key for reference
                           
                            // Process each cell
                            List<Reports.ReportDataCell> cells = row.getDataCells();
                            for (Integer i = 0; i < detailColumns.size(); i++) {
                                if (i < cells.size()) {
                                    String columnName = detailColumns[i];
                                    String columnLabel = columnToLabelMap.get(columnName);
                                   
                                    try {
                                        Object value = cells[i].getValue();
                                        rowData.put(columnLabel, value);
                                    } catch (Exception e) {
                                        rowData.put(columnLabel, '[Error: ' + e.getMessage() + ']');
                                    }
                                }
                            }
                           
                            exportData.add(rowData);
                        }
                    } else {
                        Map<String, Object> emptyData = new Map<String, Object>();
                        emptyData.put('GroupKey', key);
                        emptyData.put('Info', 'No rows found for this grouping');
                        exportData.add(emptyData);
                    }
                }
                // else if (factObject instanceof Reports.ReportFactWithSummaries) {
                //     // It's a summary report with aggregates
                //     System.debug('Found ReportFactWithSummaries for key: ' + key);
                //     try {
                //         Reports.ReportFactWithSummaries factSummaries = (Reports.ReportFactWithSummaries)factObject;
                       
                //         // Create a record for the summaries
                //         Map<String, Object> summaryData = new Map<String, Object>();
                //         summaryData.put('GroupKey', key);
                       
                //         // Get aggregate values
                //         List<Reports.SummaryValue> aggregates = factSummaries.getAggregates();
                //         if (aggregates != null && !aggregates.isEmpty()) {
                //             for (Integer i = 0; i < aggregates.size(); i++) {
                //                 try {
                //                     Object value = aggregates[i].getValue();
                //                     summaryData.put('Aggregate_' + i, value);
                //                 } catch (Exception e) {
                //                     summaryData.put('Aggregate_' + i, '[Error: ' + e.getMessage() + ']');
                //                 }
                //             }
                //         }
                       
                //         exportData.add(summaryData);
                //     } catch (Exception e) {
                //         System.debug('Error processing summary: ' + e.getMessage());
                //         Map<String, Object> errorData = new Map<String, Object>();
                //         errorData.put('GroupKey', key);
                //         errorData.put('Error', 'Error processing summary: ' + e.getMessage());
                //         exportData.add(errorData);
                //     }
                // }
                else {
                    // Unrecognized object type
                    System.debug('Unrecognized fact object type for key: ' + key);
                    Map<String, Object> typeData = new Map<String, Object>();
                    typeData.put('GroupKey', key);
                    typeData.put('Info', 'Unrecognized report data format');
                    exportData.add(typeData);
                }
            }
           
            return exportData;
        } catch (Exception e) {
            System.debug('Error in processSpecialReport: ' + e.getMessage());
            Map<String, Object> errorData = new Map<String, Object>();
            errorData.put('Error', 'Error processing special report: ' + e.getMessage());
            exportData.add(errorData);
            return exportData;
        }
    }
   
    // Method to convert a list of maps to CSV
    @AuraEnabled
    public static String convertToCSV(List<Map<String, Object>> data) {
        if (data == null || data.isEmpty()) {
            return '';
        }
        
        // Collect all keys from all records
        Set<String> allKeys = new Set<String>();
        for (Map<String, Object> record : data) {
            allKeys.addAll(record.keySet());
        }
        
        // Convert to list and sort for consistent ordering
        List<String> headers = new List<String>(allKeys);
        headers.sort();
        
        // Build the CSV string
        String csv = String.join(headers, ',') + '\n';
        
        // Add data rows
        for (Map<String, Object> record : data) {
            List<String> row = new List<String>();
            
            for (String header : headers) {
                Object value = record.get(header);
                
                // Format the value
                String cellValue = '';
                if (value != null) {
                    cellValue = String.valueOf(value);
                    
                    // Escape quotes and add quotes if needed
                    if (cellValue.contains(',') || cellValue.contains('"') || cellValue.contains('\n')) {
                        cellValue = cellValue.replace('"', '""');
                        cellValue = '"' + cellValue + '"';
                    }
                }
                
                row.add(cellValue);
            }
            
            csv += String.join(row, ',') + '\n';
        }
        
        return csv;
    }

    /**
     * Convert a Map of report data to an Excel file (XLSX) with multiple sheets
     * @param reportData Map of report names to their data
     * @return Base64 encoded Excel file
     */
    @AuraEnabled
    public static String convertToExcel(Map<String, List<Map<String, Object>>> reportData) {
        if (reportData == null || reportData.isEmpty()) {
            return '';
        }
        
        
        Map<String, String> sheetsData = new Map<String, String>();
        
        for (String reportName : reportData.keySet()) {
            List<Map<String, Object>> sheetData = reportData.get(reportName);
            
            // Convert this sheet to CSV
            String sheetCsv = convertToCSV(sheetData);
            
            // Store it with the report name
            sheetsData.put(reportName, sheetCsv);
        }
        
        // Serialize the sheets data to JSON for the JS controller
        return JSON.serialize(sheetsData);
    }


}