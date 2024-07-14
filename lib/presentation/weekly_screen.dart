import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../widgets/chart.dart';
import '../widgets/widget_utils.dart';

class DataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<WeeklyData>> getWeeklyData() async {
    List<WeeklyData> weeklyData = [];
    int currentMonth = currentDate.month;
    DateTime firstDayOfMonth = DateTime(currentDate.year, currentMonth, 1);

    for (int week = 0; week < 4; week++) {
      DateTime startOfWeek = firstDayOfMonth.add(Duration(days: week * 7));

      List<double> dailyDoAverages = [];
      List<double> dailyPhAverages = [];

      for (int day = 0; day < 7; day++) {
        DateTime currentDate = startOfWeek.add(Duration(days: day));
        var currentDateFormatted =
            "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
        String dayOfWeek = getDayOfWeek(currentDate.weekday);

        var querySnapshot = await _firestore
            .collection('history')
            .doc(currentDateFormatted)
            .collection(dayOfWeek)
            .get();

        double dailyDoSum = 0;
        double dailyPhSum = 0;
        int dataCount = querySnapshot.docs.length;

        if (dataCount > 0) {
          querySnapshot.docs.forEach((doc) {
            dailyDoSum += doc['DO'];
            dailyPhSum += doc['pH'];
          });

          dailyDoAverages.add(dailyDoSum / dataCount);
          dailyPhAverages.add(dailyPhSum / dataCount);
        }
      }

      if (dailyDoAverages.isNotEmpty && dailyPhAverages.isNotEmpty) {
        double weeklyDoAverage =
            dailyDoAverages.reduce((a, b) => a + b) / dailyDoAverages.length;
        double weeklyPhAverage =
            dailyPhAverages.reduce((a, b) => a + b) / dailyPhAverages.length;
        weeklyData.add(WeeklyData(weeklyDoAverage, weeklyPhAverage));
      }
    }
    return weeklyData;
  }

  Future<List<DailyData>> getDailyData(int weekNumber) async {
    List<DailyData> dailyData = [];
    DateTime now = DateTime.now();
    int currentMonth = now.month;
    DateTime firstDayOfMonth = DateTime(now.year, currentMonth, 1);
    DateTime startOfWeek =
        firstDayOfMonth.add(Duration(days: (weekNumber - 1) * 7));

    for (int day = 0; day < 7; day++) {
      DateTime currentDate = startOfWeek.add(Duration(days: day));
      var currentDateFormatted =
          "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
      String dayOfWeek = getDayOfWeek(currentDate.weekday);

      var querySnapshot = await _firestore
          .collection('history')
          .doc(currentDateFormatted)
          .collection(dayOfWeek)
          .get();

      double dailyDoSum = 0;
      double dailyPhSum = 0;
      int dataCount = querySnapshot.docs.length;

      if (dataCount > 0) {
        querySnapshot.docs.forEach((doc) {
          dailyDoSum += doc['DO'];
          dailyPhSum += doc['pH'];
        });

        dailyData
            .add(DailyData(dailyDoSum / dataCount, dailyPhSum / dataCount));
      } else {
        dailyData.add(DailyData(0, 0));
      }
    }

    return dailyData;
  }
}

class WeeklyScreen extends StatefulWidget {
  @override
  _WeeklyScreenState createState() => _WeeklyScreenState();
}

class _WeeklyScreenState extends State<WeeklyScreen> {
  final DataService _dataService = DataService();

  // final List<DateTime?> selectedDatesFromCalendar = [];
  List<WeeklyData> _weeklyData = [];
  List<DailyData>? _dailyData;
  Stream<List<DailyData>>? _dailyDataStream;
  int _activeButtonIndex = -1;

  @override
  void initState() {
    super.initState();
    _fetchWeeklyData();
  }

  Future<void> _fetchWeeklyData() async {
    final data = await _dataService.getWeeklyData();
    setState(() {
      _weeklyData = data;
    });
  }

  Future<void> _fetchDailyData(int weekNumber) async {
    final data = await _dataService.getDailyData(weekNumber);
    setState(() {
      _dailyData = data;
    });
  }

  // Stream<List<DailyData>> _fetchDailyData(int weekNumber) async* {
  //   yield await _dataService.getDailyData(weekNumber);
  // }

  void _showDataForWeek(BuildContext context, int weekNumber) {
    if (weekNumber <= _weeklyData.length) {
      final data = _weeklyData[weekNumber - 1];
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.indigo,
          title: Text(
            'Data for Week $weekNumber',
          ),
          content: Text(
            'DO Average: ${data.doAverageFormatted}\nPH Average: ${data.phAverageFormatted}',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No data available for Week $weekNumber')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Rata-rata Mingguan'),
                )),
            FutureBuilder<List<WeeklyData>>(
              future: _dataService.getWeeklyData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Tidak ada data tersedia'));
                }

                return SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            for (int i = 1; i <= 4; i++)
                              Container(
                                padding: EdgeInsets.all(10),
                                child: ElevatedButton(
                                  onPressed: () => _showDataForWeek(context, i),
                                  child: Text(
                                    'Minggu $i',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ButtonStyle(
                                    shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    padding: MaterialStateProperty.all(
                                        EdgeInsets.only(
                                            bottom: 5, left: 8, right: 8)),
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                            Colors.blueGrey),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(
              height: 15,
            ),
            Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Rata-rata Harian'),
                )),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text('DO')],
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Container(
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'pH',
                          style: TextStyle(color: Colors.white),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _dailyData != null
                  ? BarChartSample2(dailyData: _dailyData!)
                  : Center(
                      child: Text('Pilih minggu untuk melihat detail harian')),
            ),
            // Expanded(
            //   child: StreamBuilder<List<DailyData>>(
            //     stream: _dailyDataStream,
            //     builder: (context, snapshot) {
            //       if (snapshot.connectionState == ConnectionState.waiting) {
            //         return Center(child: CircularProgressIndicator());
            //       } else if (snapshot.hasError) {
            //         return Center(child: Text('Error: ${snapshot.error}'));
            //       } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            //         return Center(
            //             child:
            //                 Text('Pilih minggu untuk melihat detail harian'));
            //       }
            //
            //       // Update _dailyData saat stream berubah
            //       _dailyDataStream = _fetchDailyData(_activeButtonIndex);
            //
            //       return BarChartSample2(dailyData: snapshot.data!);
            //     },
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text('Hari perminggu'),
            ),
            Container(
              decoration: BoxDecoration(color: Colors.amber),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 1; i <= 4; i++)
                    Container(
                      padding: EdgeInsets.all(10),
                      child: ElevatedButton(
                        onPressed: () {
                          _fetchDailyData(i);
                          setState(() {
                            _activeButtonIndex = i;
                          });
                        },
                        child: Text(
                          'Minggu $i',
                          style: TextStyle(
                            color: _activeButtonIndex == i
                                ? Colors.teal
                                : Colors.white,
                          ),
                        ),
                        style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          padding: MaterialStateProperty.all(
                              EdgeInsets.only(bottom: 5, left: 8, right: 8)),
                          backgroundColor: MaterialStateProperty.all<Color>(
                            _activeButtonIndex == i
                                ? Colors.white
                                : Colors.teal,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BarChartSample2 extends StatelessWidget {
  final List<DailyData> dailyData;

  BarChartSample2({required this.dailyData});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 38),
            Expanded(
              child: BarChart(
                BarChartData(
                  maxY: 14,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          rod.toY.toString(),
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    touchCallback: (FlTouchEvent event, response) {},
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: bottomTitles,
                        reservedSize: 42,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 2,
                        getTitlesWidget: leftTitles,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  barGroups: _generateDailyBarGroups(),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateDailyBarGroups() {
    return List.generate(dailyData.length, (i) {
      final daily = dailyData[i];
      return BarChartGroupData(
        barsSpace: 4,
        x: i,
        barRods: [
          BarChartRodData(
            toY: daily.doAverage,
            color: Colors.amber,
            width: 7,
          ),
          BarChartRodData(
            toY: daily.phAverage,
            color: Colors.indigo,
            width: 7,
          ),
        ],
      );
    });
  }

  Widget leftTitles(double value, TitleMeta meta) {
    if (value % 2 == 0 && value <= 14) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 0,
        child: Text(
          value.toInt().toString(),
          style: const TextStyle(
            color: Color(0xff7589a2),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    final titles = <String>['1', '2', '3', '4', '5', '6', '7'];

    final Widget text = Text(
      titles[value.toInt()],
      style: const TextStyle(
        color: Color(0xff7589a2),
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 16,
      child: text,
    );
  }
}
