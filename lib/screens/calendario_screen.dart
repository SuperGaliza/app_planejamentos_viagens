import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/viagem.dart';
import 'detalhes_viagem_screen.dart';

class CalendarioScreen extends StatefulWidget {
  final List<Viagem> viagens;

  const CalendarioScreen({super.key, required this.viagens});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _diaSelecionado = DateTime.now();
  DateTime _focado = DateTime.now();

  List<Viagem> _viagensNoDia(DateTime dia) {
    return widget.viagens.where((viagem) {
        return dia.isAfter(viagem.dataIda.subtract(const Duration(days: 1))) &&
            dia.isBefore(viagem.dataChegada.add(const Duration(days: 1)));
      }).toList()
      ..sort((a, b) => a.dataIda.compareTo(b.dataIda));
  }

  Color _getCorViagem(String? corHex) {
    try {
      return Color(int.parse(corHex ?? '0xff2196f3')); // Azul padrão
    } catch (_) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viagensDoDia = _viagensNoDia(_diaSelecionado);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário de Viagens'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Hoje',
            onPressed: () {
              setState(() {
                _diaSelecionado = DateTime.now();
                _focado = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<Viagem>(
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            focusedDay: _focado,
            selectedDayPredicate: (day) => isSameDay(day, _diaSelecionado),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _diaSelecionado = selectedDay;
                _focado = focusedDay;
              });
            },
            eventLoader: _viagensNoDia,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.orange.shade400,
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders<Viagem>(
              markerBuilder: (context, day, eventos) {
                if (eventos.isEmpty) return null;

                final viagens = eventos.cast<Viagem>();

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      viagens.take(3).map((viagem) {
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 0.5),
                          decoration: BoxDecoration(
                            color: _getCorViagem(viagem.corHex),
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                );
              },
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Viagens em ${_diaSelecionado.day}/${_diaSelecionado.month}/${_diaSelecionado.year}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          Expanded(
            child:
                viagensDoDia.isEmpty
                    ? const Center(child: Text('Nenhuma viagem neste dia.'))
                    : ListView.separated(
                      itemCount: viagensDoDia.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final viagem = viagensDoDia[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getCorViagem(viagem.corHex),
                            child: const Icon(
                              Icons.flight_takeoff,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(viagem.titulo),
                          subtitle: Text(viagem.destino),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => DetalhesViagemScreen(viagem: viagem),
                              ),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
