import 'dart:html' as html;

import 'package:csv/csv.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CustomDataTable(),
    );
  }
}

class CustomDataTable extends StatefulWidget {
  const CustomDataTable({super.key});

  @override
  _CustomDataTableState createState() => _CustomDataTableState();
}

class _CustomDataTableState extends State<CustomDataTable> {
  int _sortColumnIndex = 0;
  bool _isAscending = true;
  String? _statusFilter;
  DateTimeRange? _dateRange;

  final DateFormat _dateFormat = DateFormat('dd-MM-yyyy');

  List<Map<String, String>> _originalData = [
    {'name': 'John', 'age': '25', 'city': 'USA', 'status': 'Active', 'date': '31-12-2024'},
    {'name': 'Bob', 'age': '30', 'city': 'Los Angeles', 'status': 'Inactive', 'date': '15-11-2024'},
    {'name': 'Charlie', 'age': '28', 'city': 'Chicago', 'status': 'Active', 'date': '20-10-2024'},
    {'name': 'Diana', 'age': '22', 'city': 'Miami', 'status': 'Active', 'date': '22-01-2025'},
    {'name': 'Alice', 'age': '24', 'city': 'New York', 'status': 'Inactive', 'date': '22-02-2024'}
  ];

  List<Map<String, String>> get _filteredData {
    return _originalData.where((row) {
      DateTime? rowDate;
      try {
        rowDate = _dateFormat.parse(row['date']!);
      } catch (e) {
        return false; // Skip rows with invalid dates
      }

      // Apply status filter
      if (_statusFilter != null && row['status'] != _statusFilter) {
        return false;
      }

      // Apply date range filter
      if (_dateRange != null) {
        if (rowDate.isBefore(_dateRange!.start) || rowDate.isAfter(_dateRange!.end)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _sort<T>(Comparable<T> Function(Map<String, String> d) getField,
      int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
      _originalData.sort((a, b) {
        final result = Comparable.compare(getField(a), getField(b));
        return ascending ? result : -result;
      });
    });
  }

  Future<void> _exportToCsvWeb(List<Map<String, String>> data) async {
    List<List<String>> csvData = [
      ['Name', 'Age', 'City', 'Status', 'Date'],
      ...data.map((row) => [
            row['name'] ?? '',
            row['age'] ?? '',
            row['city'] ?? '',
            row['status'] ?? '',
            row['date'] ?? '',
          ])
    ];

    String csv = const ListToCsvConverter().convert(csvData);

    final bytes = html.Blob([csv], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(bytes);
    final anchor = html.AnchorElement(href: url)
      ..target = 'blank'
      ..download = 'filtered_data.csv'
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _confirmExport() async {
    final filteredData = _filteredData;

    if (_statusFilter == null && _dateRange == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Filters Applied'),
          content: const Text('Please apply a status filter or a date range to export data.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (filteredData.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Data to Export'),
          content: const Text('No data matches the selected filters.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export to CSV'),
        content: const Text('Are you sure you want to export the filtered data to a CSV file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Export'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _exportToCsvWeb(filteredData);
    }
  }

  Future<void> _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2025),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _filteredData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Table with Filters & Export'),
        actions: [
          IconButton(
            onPressed: _confirmExport,
            icon: const Icon(Icons.download),
            tooltip: 'Export to CSV',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter by Status:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Radio<String?>(
                            value: null,
                            groupValue: _statusFilter,
                            onChanged: (value) {
                              setState(() {
                                _statusFilter = value;
                              });
                            },
                          ),
                          const Text('Any'),
                          Radio<String?>(
                            value: 'Active',
                            groupValue: _statusFilter,
                            onChanged: (value) {
                              setState(() {
                                _statusFilter = value!;
                              });
                            },
                          ),
                          const Text('Active'),
                          Radio<String?>(
                            value: 'Inactive',
                            groupValue: _statusFilter,
                            onChanged: (value) {
                              setState(() {
                                _statusFilter = value!;
                              });
                            },
                          ),
                          const Text('Inactive'),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _pickDateRange,
                  child: Text(
                    _dateRange == null
                        ? 'Pick Date Range'
                        : 'From: ${_dateFormat.format(_dateRange!.start)} To: ${_dateFormat.format(_dateRange!.end)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          // Message or Table
          if (_statusFilter == null && _dateRange == null)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Please set a status filter or a date range to view the data.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          else if (filteredData.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No data matches the selected filters.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          else
            Expanded(
              child: DataTable2(
                columnSpacing: 24,
                horizontalMargin: 10,
                minWidth: 600,
                headingRowHeight: 56,
                dataRowHeight: 60,
                headingRowColor: MaterialStateProperty.all(Colors.deepPurple),
                dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                  (states) {
                    if (states.contains(MaterialState.hovered)) {
                      return Colors.deepPurple.withOpacity(0.1);
                    }
                    return null;
                  },
                ),
                columns: [
                  DataColumn2(
                    label: const Text(
                      'Name',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    onSort: (columnIndex, ascending) {
                      _sort<String>((d) => d['name']!, columnIndex, ascending);
                    },
                    size: ColumnSize.M,
                  ),
                  DataColumn2(
                    label: const Text(
                      'Age',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    onSort: (columnIndex, ascending) {
                      _sort<String>((d) => d['age']!, columnIndex, ascending);
                    },
                    size: ColumnSize.M,
                  ),
                  DataColumn2(
                    label: const Text(
                      'City',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    size: ColumnSize.M,
                  ),
                  DataColumn2(
                    label: const Text(
                      'Status',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    size: ColumnSize.S,
                  ),
                  DataColumn2(
                    label: const Text(
                      'Date',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    size: ColumnSize.M,
                  ),
                ],
                rows: filteredData
                    .map((data) => DataRow(
                          cells: [
                            DataCell(Text(data['name']!)),
                            DataCell(Text(data['age']!)),
                            DataCell(Text(data['city']!)),
                            DataCell(Text(data['status']!)),
                            DataCell(Text(data['date']!)),
                          ],
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
