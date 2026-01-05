import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../models/transaction.dart';

/// Insights screen with charts and analytics
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          onRefresh: () => provider.initialize(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),

              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Net Worth',
                      value: provider.netAmount,
                      icon: Icons.account_balance,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'To Get Back',
                      value: provider.totalToGetBack,
                      icon: Icons.payments,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Spending by Tag (Pie Chart)
              _buildSpendingByTagSection(provider),
              const SizedBox(height: 24),

              // Net Worth Over Time (Line Chart)
              _buildNetWorthChartSection(provider),
              const SizedBox(height: 24),

              // Account Distribution
              _buildAccountDistribution(provider),
              const SizedBox(height: 24),

              // Essential vs Non-Essential Spending (Pie Chart)
              _buildEssentialVsNonEssentialSection(provider),
              const SizedBox(height: 24),

              // Monthly Spending (Bar Chart)
              _buildMonthlySpendingSection(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(value),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingByTagSection(AppProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            FutureBuilder<Map<String, double>>(
              future: provider.getSpendingByTag(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final spending = snapshot.data ?? {};
                if (spending.isEmpty) {
                  return _buildEmptyChartState('No spending data yet');
                }

                return _buildPieChart(spending);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> spending) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];

    final sortedEntries = spending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = spending.values.fold(0.0, (sum, val) => sum + val);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sortedEntries.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final percentage = (data.value / total) * 100;

                return PieChartSectionData(
                  value: data.value,
                  title: '${percentage.toStringAsFixed(1)}%',
                  color: colors[index % colors.length],
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: sortedEntries.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${data.key}: ${NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(data.value)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNetWorthChartSection(AppProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Net Worth Over Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            FutureBuilder<List<Transaction>>(
              future: provider.getNetWorthHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final transactions = snapshot.data ?? [];
                if (transactions.isEmpty) {
                  return _buildEmptyChartState('No transaction history');
                }

                return _buildLineChart(transactions);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<Transaction> transactions) {
    if (transactions.length < 2) {
      return _buildEmptyChartState('Need at least 2 transactions');
    }

    // Create data points
    final spots = transactions.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.net);
    }).toList();

    final minY = transactions.map((t) => t.net).reduce((a, b) => a < b ? a : b);
    final maxY = transactions.map((t) => t.net).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: range > 0 ? range / 4 : 1,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact().format(value),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (transactions.length / 5).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= transactions.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MM/dd').format(transactions[index].date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[300]!),
          ),
          minY: minY - (range * 0.1),
          maxY: maxY + (range * 0.1),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.blue,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDistribution(AppProvider provider) {
    final accounts = provider.accounts;
    if (accounts.isEmpty) return const SizedBox.shrink();

    final total = provider.netAmount;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...accounts.map((account) {
              final percentage = total > 0 ? (account.balance / total) * 100 : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          account.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${NumberFormat.currency(symbol: '₹').format(account.balance)} (${percentage.toStringAsFixed(1)}%)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: total > 0 ? account.balance / total : 0,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getAccountColor(account.name),
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChartState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.insert_chart,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAccountColor(String accountName) {
    switch (accountName) {
      case 'Bank':
        return Colors.blue;
      case 'Cash':
        return Colors.green;
      case 'Wallet':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEssentialVsNonEssentialSection(AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Essential vs Non-Essential',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, double>>(
              future: provider.getEssentialVsNonEssentialSpending(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyChartState('No spending data available');
                }

                final data = snapshot.data!;
                final essential = data['Essential'] ?? 0.0;
                final nonEssential = data['Non-Essential'] ?? 0.0;
                final total = essential + nonEssential;

                if (total == 0) {
                  return _buildEmptyChartState('No spending data available');
                }

                return Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: essential,
                              title: '${((essential / total) * 100).toStringAsFixed(1)}%',
                              color: Colors.green,
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              value: nonEssential,
                              title: '${((nonEssential / total) * 100).toStringAsFixed(1)}%',
                              color: Colors.orange,
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildLegendItem('Essential', Colors.green, essential),
                        _buildLegendItem('Non-Essential', Colors.orange, nonEssential),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySpendingSection(AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Spending',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Last 12 months',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, double>>(
              future: provider.getMonthlySpending(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyChartState('No spending data available');
                }

                final data = snapshot.data!;
                final months = data.keys.toList().reversed.toList();
                final maxSpending = data.values.reduce((a, b) => a > b ? a : b);

                return SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxSpending * 1.2,
                      barGroups: months.asMap().entries.map((entry) {
                        final index = entry.key;
                        final month = entry.value;
                        final amount = data[month] ?? 0.0;

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: amount,
                              color: Colors.blue,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                _formatCompactNumber(value),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= months.length) {
                                return const Text('');
                              }
                              final month = months[value.toInt()];
                              final parts = month.split('-');
                              if (parts.length == 2) {
                                return Text(
                                  '${parts[1]}/${parts[0].substring(2)}',
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxSpending / 5,
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, double amount) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(amount),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatCompactNumber(double value) {
    if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}
