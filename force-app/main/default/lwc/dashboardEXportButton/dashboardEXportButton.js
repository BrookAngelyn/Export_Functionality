

// import { LightningElement, api, wire, track } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { NavigationMixin } from 'lightning/navigation';
// import { loadScript } from 'lightning/platformResourceLoader';
// import exportDashboardData from '@salesforce/apex/DashboardExportController.exportDashboardData';
// import getDashboardComponents from '@salesforce/apex/DashboardExportController.getDashboardComponents';
// import XLSX_LIB from '@salesforce/resourceUrl/xlsx_lib';

// export default class DashboardExportBtn extends NavigationMixin(LightningElement) {
//     @api recordId;
//     isLoading = false;
//     xlsxInitialized = false;
//     @track componentOptions = [];
//     @track selectedComponent = 'All Components';
//     @track loadingComponents = true;
//     @track error;

//     connectedCallback() {
//         // Load XLSX library
//         if (!this.xlsxInitialized) {
//             loadScript(this, XLSX_LIB)
//                 .then(() => {
//                     this.xlsxInitialized = true;
//                     console.log('XLSX library loaded successfully');
//                 })
//                 .catch(error => {
//                     console.error('Error loading XLSX library:', error);
//                     this.showToast('Error', 'Failed to load Excel export functionality', 'error');
//                 });
//         }
        
//         // Load dashboard components
//         this.loadDashboardComponents();
//     }

//     loadDashboardComponents() {
//         this.loadingComponents = true;
//         this.error = null;
        
//         getDashboardComponents({ dashboardId: this.recordId || '01Z000000000000' })
//             .then(result => {
//                 if (result && Array.isArray(result) && result.length > 0) {
//                     // Add "All Components" as the first option
//                     this.componentOptions = [
//                         { label: 'All Components', value: 'All Components' }
//                     ];
                    
//                     // Add each component from the result
//                     result.forEach(name => {
//                         this.componentOptions.push({
//                             label: name,
//                             value: name
//                         });
//                     });
                    
//                     // Set default selection to "All Components"
//                     this.selectedComponent = 'All Components';
//                 } else {
//                     // No components found
//                     this.componentOptions = [
//                         { label: 'All Components', value: 'All Components' }
//                     ];
//                     this.error = 'No components found for this dashboard';
//                 }
//             })
//             .catch(error => {
//                 console.error('Error loading dashboard components:', error);
//                 // Fallback to just "All Components"
//                 this.componentOptions = [
//                     { label: 'All Components', value: 'All Components' }
//                 ];
//                 this.error = 'Error loading dashboard components: ' + this.extractErrorMessage(error);
//             })
//             .finally(() => {
//                 this.loadingComponents = false;
//             });
//     }

//     handleComponentChange(event) {
//         this.selectedComponent = event.detail.value;
//     }

//     extractErrorMessage(error) {
//         let message = 'Unknown error';
//         if (typeof error === 'string') {
//             message = error;
//         } else if (error.message) {
//             message = error.message;
//         } else if (error.body && error.body.message) {
//             message = error.body.message;
//         }
//         return message;
//     }

//     handleExportClick() {
//         if (!this.xlsxInitialized) {
//             this.showToast('Error', 'Excel export library is still loading. Please try again in a moment.', 'error');
//             return;
//         }

//         console.log('Export button clicked');
//         console.log('Dashboard ID:', this.recordId);
//         console.log('Selected component:', this.selectedComponent);
        
//         this.isLoading = true;
        
//         exportDashboardData({
//             dashboardId: this.recordId || '01Z000000000000',
//             componentName: this.selectedComponent
//         })
//             .then(result => {
//                 console.log('Export result received');
                
//                 if (result && typeof result === 'object' && !Array.isArray(result)) {
//                     // Handle the multi-report object structure
                    
//                     if (this.selectedComponent === 'All Components') {
//                         // For "All Components", export separate files
//                         let exportCount = 0;
                        
//                         Object.keys(result).forEach(reportName => {
//                             if (Array.isArray(result[reportName]) && result[reportName].length > 0) {
//                                 const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
//                                 const sanitizedName = reportName.replace(/[^a-zA-Z0-9_]/g, '_').toLowerCase();
//                                 const fileName = `${sanitizedName}_${timestamp}`;
                                
//                                 this.exportData(result[reportName], fileName);
//                                 exportCount++;
//                             }
//                         });
                        
//                         if (exportCount > 0) {
//                             this.showToast('Success', `${exportCount} reports exported successfully`, 'success');
//                         } else {
//                             this.showToast('Warning', 'No data found to export', 'warning');
//                         }
//                     } else {
//                         // Single component selected
//                         const componentData = result[this.selectedComponent];
                        
//                         if (Array.isArray(componentData) && componentData.length > 0) {
//                             const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
//                             const sanitizedName = this.selectedComponent.replace(/[^a-zA-Z0-9_]/g, '_').toLowerCase();
//                             const fileName = `${sanitizedName}_${timestamp}`;
                            
//                             this.exportData(componentData, fileName);
//                             this.showToast('Success', 'Report exported successfully', 'success');
//                         } else {
//                             this.showToast('Warning', 'No data found to export for this component', 'warning');
//                         }
//                     }
//                 } else if (Array.isArray(result) && result.length > 0) {
//                     // Handle single array result
//                     const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
//                     const sanitizedName = this.selectedComponent.replace(/[^a-zA-Z0-9_]/g, '_').toLowerCase();
//                     const fileName = `${sanitizedName}_${timestamp}`;
                    
//                     this.exportData(result, fileName);
//                     this.showToast('Success', 'Report exported successfully', 'success');
//                 } else {
//                     this.showToast('Warning', 'No data found to export', 'warning');
//                 }
//             })
//             .catch(error => {
//                 console.error('Error exporting dashboard data:', error);
//                 this.showToast('Error', 'Failed to export dashboard data: ' + this.extractErrorMessage(error), 'error');
//             })
//             .finally(() => {
//                 this.isLoading = false;
//             });
//     }

//     exportData(data, fileName) {
//         try {
//             // Determine if user prefers CSV or Excel
//             const exportAsExcel = true; // You can make this configurable via a toggle

//             if (exportAsExcel) {
//                 this.downloadExcel(data, fileName + '.xlsx');
//             } else {
//                 this.downloadCSV(data, fileName + '.csv');
//             }
//         } catch (error) {
//             console.error('Export error:', error);
//             // Fallback to CSV if Excel export fails
//             this.downloadCSV(data, fileName + '.csv');
//         }
//     }

//     downloadExcel(data, fileName) {
//         if (!this.xlsxInitialized || !window.XLSX) {
//             console.error('XLSX library not loaded');
//             this.showToast('Error', 'Excel export library not loaded properly. Falling back to CSV.', 'error');
//             this.downloadCSV(data, fileName.replace('.xlsx', '.csv'));
//             return;
//         }

//         try {
//             // Create a new workbook
//             const wb = window.XLSX.utils.book_new();
            
//             // Convert data to worksheet
//             const ws = window.XLSX.utils.json_to_sheet(data);
            
//             // Add worksheet to workbook
//             window.XLSX.utils.book_append_sheet(wb, ws, 'Dashboard Data');
            
//             // Generate Excel file and trigger download
//             window.XLSX.writeFile(wb, fileName);
//         } catch (error) {
//             console.error('Excel export error:', error);
//             // Fallback to CSV
//             this.showToast('Warning', 'Excel export failed. Falling back to CSV.', 'warning');
//             this.downloadCSV(data, fileName.replace('.xlsx', '.csv'));
//         }
//     }

//     downloadCSV(data, fileName) {
//         if (!data || !Array.isArray(data) || data.length === 0) {
//             this.showToast('Warning', 'No data to export', 'warning');
//             return;
//         }

//         try {
//             // Get headers from first data object
//             const headers = Object.keys(data[0]);
            
//             // Create CSV content
//             let csvContent = headers.join(',') + '\n';
            
//             // Add data rows
//             data.forEach(row => {
//                 const values = headers.map(header => {
//                     const value = row[header];
//                     // Handle values containing commas, quotes, etc.
//                     if (value === null || value === undefined) {
//                         return '';
//                     } else if (typeof value === 'string') {
//                         // Escape quotes and wrap in quotes if needed
//                         const escapedValue = value.replace(/"/g, '""');
//                         return /[",\n\r]/.test(value) ? `"${escapedValue}"` : escapedValue;
//                     } else {
//                         return value;
//                     }
//                 });
//                 csvContent += values.join(',') + '\n';
//             });
            
//             // Create blob and download
//             const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
//             this.downloadBlob(blob, fileName);
//         } catch (error) {
//             console.error('CSV generation error:', error);
//             this.showToast('Error', 'Failed to generate CSV: ' + this.extractErrorMessage(error), 'error');
//         }
//     }

//     downloadBlob(blob, fileName) {
//         try {
//             // Create download link
//             const url = window.URL.createObjectURL(blob);
//             const link = document.createElement('a');
//             link.href = url;
//             link.download = fileName;
            
//             // Append to DOM, click, and remove
//             document.body.appendChild(link);
//             link.click();
            
//             // Clean up
//             window.setTimeout(() => {
//                 document.body.removeChild(link);
//                 window.URL.revokeObjectURL(url);
//             }, 0);
//         } catch (error) {
//             console.error('Download error:', error);
//             this.showToast('Error', 'Failed to download file: ' + this.extractErrorMessage(error), 'error');
//         }
//     }

//     showToast(title, message, variant) {
//         const event = new ShowToastEvent({
//             title: title,
//             message: message,
//             variant: variant
//         });
//         this.dispatchEvent(event);
//     }
// }


import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { loadScript } from 'lightning/platformResourceLoader';
import exportDashboardData from '@salesforce/apex/DashboardExportController.exportDashboardData';
import getDashboardComponents from '@salesforce/apex/DashboardExportController.getDashboardComponents';
import XLSX_LIB from '@salesforce/resourceUrl/xlsx_lib';

export default class DashboardExportBtn extends NavigationMixin(LightningElement) {
    @api recordId;
    isLoading = false;
    xlsxInitialized = false;
    @track componentOptions = [];
    @track selectedComponent = 'All Components';
    @track loadingComponents = true;
    @track error;
    @track debugMode = false; // Add debug mode toggle

    connectedCallback() {
        // Load XLSX library
        if (!this.xlsxInitialized) {
            loadScript(this, XLSX_LIB)
                .then(() => {
                    this.xlsxInitialized = true;
                    console.log('XLSX library loaded successfully');
                })
                .catch(error => {
                    console.error('Error loading XLSX library:', error);
                    this.showToast('Error', 'Failed to load Excel export functionality', 'error');
                });
        }
        
        // Load dashboard components
        this.loadDashboardComponents();
    }

    loadDashboardComponents() {
        this.loadingComponents = true;
        this.error = null;
        
        getDashboardComponents({ dashboardId: this.recordId || '01Z000000000000' })
            .then(result => {
                if (result && Array.isArray(result) && result.length > 0) {
                    // Add "All Components" as the first option
                    this.componentOptions = [
                        { label: 'All Components', value: 'All Components' }
                    ];
                    
                    // Add each component from the result
                    result.forEach(name => {
                        this.componentOptions.push({
                            label: name,
                            value: name
                        });
                    });
                    
                    // Set default selection to "All Components"
                    this.selectedComponent = 'All Components';
                } else {
                    // No components found
                    this.componentOptions = [
                        { label: 'All Components', value: 'All Components' }
                    ];
                    this.error = 'No components found for this dashboard';
                }
            })
            .catch(error => {
                console.error('Error loading dashboard components:', error);
                // Fallback to just "All Components"
                this.componentOptions = [
                    { label: 'All Components', value: 'All Components' }
                ];
                this.error = 'Error loading dashboard components: ' + this.extractErrorMessage(error);
            })
            .finally(() => {
                this.loadingComponents = false;
            });
    }

    handleComponentChange(event) {
        this.selectedComponent = event.detail.value;
    }

    toggleDebugMode() {
        this.debugMode = !this.debugMode;
        this.showToast('Debug Mode', this.debugMode ? 'Debug Mode enabled' : 'Debug Mode disabled', 'info');
    }

    extractErrorMessage(error) {
        let message = 'Unknown error';
        if (typeof error === 'string') {
            message = error;
        } else if (error.message) {
            message = error.message;
        } else if (error.body && error.body.message) {
            message = error.body.message;
        }
        return message;
    }


    handleExportClick() {
    if (!this.xlsxInitialized) {
        this.showToast('Error', 'Excel export library is still loading. Please try again in a moment.', 'error');
        return;
    }

    console.log('Export button clicked');
    console.log('Dashboard ID:', this.recordId);
    console.log('Selected component:', this.selectedComponent);
    
    this.isLoading = true;
    
    exportDashboardData({
        dashboardId: this.recordId || '01Z000000000000',
        componentName: this.selectedComponent
    })
        .then(result => {
            console.log('Export result received');
            
            if (result && typeof result === 'object' && !Array.isArray(result)) {
                // Handle the multi-report object structure
                let reportCount = Object.keys(result).length;
                let reportsWithData = 0;
                let totalRecords = 0;
                let hasData = false;
                
                console.log(`Found ${reportCount} reports in result`);
                
                // Check if any of the reports have data
                Object.keys(result).forEach(reportName => {
                    if (Array.isArray(result[reportName]) && result[reportName].length > 0) {
                        // Count records excluding pure error records
                        const realDataRecords = result[reportName].filter(record => 
                            !record.Error && !record.Info);
                        
                        if (realDataRecords.length > 0) {
                            console.log(`Report "${reportName}" has ${realDataRecords.length} real data records`);
                            reportsWithData++;
                            totalRecords += realDataRecords.length;
                            hasData = true;
                        } else if (this.debugMode) {
                            // In debug mode, count reports with just error messages too
                            console.log(`Report "${reportName}" has only diagnostic data`);
                            reportsWithData++;
                            totalRecords += result[reportName].length;
                            hasData = true;
                        } else {
                            console.log(`Report "${reportName}" has no usable data, only diagnostic messages`);
                        }
                    } else {
                        console.log(`Report "${reportName}" has no data`);
                    }
                });
                
                console.log(`Reports with data: ${reportsWithData} out of ${reportCount}`);
                console.log(`Total records: ${totalRecords}`);
                
                if (!hasData) {
                    this.showToast('Warning', 'No valid data found to export in any report. Try enabling debug mode to see diagnostic information.', 'warning');
                    this.isLoading = false;
                    return;
                }
                
                if (this.selectedComponent === 'All Components') {
                    // For "All Components", create a single Excel file with multiple sheets
                    this.exportCombinedExcel(result);
                    this.showToast('Success', `Exported data from ${reportsWithData} dashboard components (${totalRecords} total records)`, 'success');
                } else {
                    // Single component selected - still export as a single file
                    const componentData = [];
                    
                    // Collect data from all matching reports
                    Object.keys(result).forEach(reportName => {
                        if (Array.isArray(result[reportName]) && result[reportName].length > 0) {
                            // Add the report name to each record if it's not already there
                            result[reportName].forEach(record => {
                                if (!record.Report_Name) {
                                    record.Report_Name = reportName;
                                }
                            });
                            componentData.push(...result[reportName]);
                        }
                    });
                    
                    if (componentData.length > 0) {
                        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
                        const sanitizedName = this.selectedComponent.replace(/[^a-zA-Z0-9_]/g, '_').toLowerCase();
                        const fileName = `${sanitizedName}_${timestamp}`;
                        
                        this.exportData(componentData, fileName);
                        this.showToast('Success', `Component data exported successfully (${componentData.length} records)`, 'success');
                    } else {
                        this.showToast('Warning', 'No data found to export for this component', 'warning');
                    }
                }
            } else if (Array.isArray(result) && result.length > 0) {
                // Handle single array result
                const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
                const sanitizedName = this.selectedComponent.replace(/[^a-zA-Z0-9_]/g, '_').toLowerCase();
                const fileName = `${sanitizedName}_${timestamp}`;
                
                this.exportData(result, fileName);
                this.showToast('Success', `Report exported successfully (${result.length} records)`, 'success');
            } else {
                this.showToast('Warning', 'No data found to export', 'warning');
            }
        })
        .catch(error => {
            console.error('Error exporting dashboard data:', error);
            this.showToast('Error', 'Failed to export dashboard data: ' + this.extractErrorMessage(error), 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    exportCombinedExcel(reportData) {
        if (!this.xlsxInitialized || !window.XLSX) {
            console.error('XLSX library not loaded');
            this.showToast('Error', 'Excel export library not loaded. Exporting individual files instead.', 'error');
            
            // Fall back to individual exports
            Object.keys(reportData).forEach(reportName => {
                if (Array.isArray(reportData[reportName]) && reportData[reportName].length > 0) {
                    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
                    const sanitizedName = reportName.replace(/[^a-zA-Z0-9_]/g, '_').toLowerCase();
                    const fileName = `${sanitizedName}_${timestamp}`;
                    
                    this.exportData(reportData[reportName], fileName);
                }
            });
            
            return;
        }
        
        try {
            // Create a new workbook for the combined export
            const wb = window.XLSX.utils.book_new();
            const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
            let anySheetAdded = false;
            
            // Add each report as a separate sheet
            Object.keys(reportData).forEach(reportName => {
                const data = reportData[reportName];
                
                if (Array.isArray(data) && data.length > 0) {
                    // Skip sheets that only contain error messages unless in debug mode
                    const onlyErrors = data.every(record => record.Error || record.Info);
                    if (onlyErrors && !this.debugMode) {
                        return;
                    }
                    
                    try {
                        // Create sanitized sheet name (Excel has a 31 char limit)
                        let sheetName = reportName.replace(/[*?:/\\[\]]/g, '_');
                        if (sheetName.length > 31) {
                            sheetName = sheetName.substring(0, 28) + '...';
                        }
                        
                        // Convert data to worksheet
                        const ws = window.XLSX.utils.json_to_sheet(data);
                        
                        // Add worksheet to workbook
                        window.XLSX.utils.book_append_sheet(wb, ws, sheetName);
                        anySheetAdded = true;
                    } catch (sheetError) {
                        console.error(`Error adding sheet for ${reportName}:`, sheetError);
                    }
                }
            });
            
            // Only write the file if we added any sheets
            if (anySheetAdded) {
                // Generate Excel file and trigger download
                const fileName = `dashboard_export_${timestamp}.xlsx`;
                window.XLSX.writeFile(wb, fileName);
                this.showToast('Success', 'Dashboard data exported successfully', 'success');
            } else {
                this.showToast('Warning', 'No valid data found to export', 'warning');
            }
        } catch (error) {
            console.error('Combined Excel export error:', error);
            this.showToast('Error', 'Combined Excel export failed. Trying individual files...', 'error');
            
            // Fall back to individual exports
            Object.keys(reportData).forEach(reportName => {
                if (Array.isArray(reportData[reportName]) && reportData[reportName].length > 0) {
                    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
                    const sanitizedName = reportName.replace(/[^a-zA-Z0-9_]/g, '_').toLowerCase();
                    const fileName = `${sanitizedName}_${timestamp}`;
                    
                    this.exportData(reportData[reportName], fileName);
                }
            });
        }
    }

    exportData(data, fileName) {
        try {
            // Determine if user prefers CSV or Excel
            const exportAsExcel = true; // You can make this configurable via a toggle

            if (exportAsExcel) {
                this.downloadExcel(data, fileName + '.xlsx');
            } else {
                this.downloadCSV(data, fileName + '.csv');
            }
        } catch (error) {
            console.error('Export error:', error);
            // Fallback to CSV if Excel export fails
            this.downloadCSV(data, fileName + '.csv');
        }
    }

    downloadExcel(data, fileName) {
        if (!this.xlsxInitialized || !window.XLSX) {
            console.error('XLSX library not loaded');
            this.showToast('Error', 'Excel export library not loaded properly. Falling back to CSV.', 'error');
            this.downloadCSV(data, fileName.replace('.xlsx', '.csv'));
            return;
        }

        try {
            // Filter out records with only error messages unless in debug mode
            let processedData = data;
            if (!this.debugMode) {
                processedData = data.filter(record => !record.Error && !record.Info);
            }

            if (processedData.length === 0) {
                if (this.debugMode) {
                    // In debug mode, use the original data even if it only contains errors
                    processedData = data;
                } else {
                    this.showToast('Warning', 'No valid data to export after filtering error messages', 'warning');
                    return;
                }
            }

            // Create a new workbook
            const wb = window.XLSX.utils.book_new();
            
            // Convert data to worksheet
            const ws = window.XLSX.utils.json_to_sheet(processedData);
            
            // Add worksheet to workbook
            window.XLSX.utils.book_append_sheet(wb, ws, 'Dashboard Data');
            
            // Generate Excel file and trigger download
            window.XLSX.writeFile(wb, fileName);
        } catch (error) {
            console.error('Excel export error:', error);
            // Fallback to CSV
            this.showToast('Warning', 'Excel export failed. Falling back to CSV.', 'warning');
            this.downloadCSV(data, fileName.replace('.xlsx', '.csv'));
        }
    }

    downloadCSV(data, fileName) {
        if (!data || !Array.isArray(data) || data.length === 0) {
            this.showToast('Warning', 'No data to export', 'warning');
            return;
        }

        try {
            // Filter out records with only error messages unless in debug mode
            let processedData = data;
            if (!this.debugMode) {
                processedData = data.filter(record => !record.Error && !record.Info);
            }

            if (processedData.length === 0) {
                if (this.debugMode) {
                    // In debug mode, use the original data even if it only contains errors
                    processedData = data;
                } else {
                    this.showToast('Warning', 'No valid data to export after filtering error messages', 'warning');
                    return;
                }
            }

            // Get headers from all data objects
            const headerSet = new Set();
            processedData.forEach(row => {
                Object.keys(row).forEach(key => headerSet.add(key));
            });
            const headers = Array.from(headerSet);
            
            // Create CSV content
            let csvContent = headers.join(',') + '\n';
            
            // Add data rows
            processedData.forEach(row => {
                const values = headers.map(header => {
                    const value = row[header];
                    // Handle values containing commas, quotes, etc.
                    if (value === null || value === undefined) {
                        return '';
                    } else if (typeof value === 'string') {
                        // Escape quotes and wrap in quotes if needed
                        const escapedValue = value.replace(/"/g, '""');
                        return /[",\n\r]/.test(value) ? `"${escapedValue}"` : escapedValue;
                    } else {
                        return value;
                    }
                });
                csvContent += values.join(',') + '\n';
            });
            
            // Create blob and download
            const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
            this.downloadBlob(blob, fileName);
        } catch (error) {
            console.error('CSV generation error:', error);
            this.showToast('Error', 'Failed to generate CSV: ' + this.extractErrorMessage(error), 'error');
        }
    }

    downloadBlob(blob, fileName) {
        try {
            // Create download link
            const url = window.URL.createObjectURL(blob);
            const link = document.createElement('a');
            link.href = url;
            link.download = fileName;
            
            // Append to DOM, click, and remove
            document.body.appendChild(link);
            link.click();
            
            // Clean up
            window.setTimeout(() => {
                document.body.removeChild(link);
                window.URL.revokeObjectURL(url);
            }, 0);
        } catch (error) {
            console.error('Download error:', error);
            this.showToast('Error', 'Failed to download file: ' + this.extractErrorMessage(error), 'error');
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}