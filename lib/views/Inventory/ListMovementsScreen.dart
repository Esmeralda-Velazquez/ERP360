import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:erpraf/controllers/MovementsProvider.dart';
import 'package:intl/intl.dart';
import 'package:erpraf/views/Inventory/CreateMovementScreen.dart';
import 'package:url_launcher/url_launcher.dart';

class ListMovementsScreen extends StatefulWidget {
  const ListMovementsScreen({super.key});

  @override
  State<ListMovementsScreen> createState() => _ListMovementsScreenState();
}

class _ListMovementsScreenState extends State<ListMovementsScreen> {
  final _productIdCtrl = TextEditingController();
  String? _type; // IN / OUT / ADJ
  DateTime? _from;
  DateTime? _to;

  late MovementsProvider movProv;
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      movProv = context.read<MovementsProvider>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        movProv.fetch(); // carga inicial
      });
      _didInit = true;
    }
  }

  @override
  void dispose() {
    _productIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool from}) async {
    final now = DateTime.now();
    final init = from ? (_from ?? DateTime(now.year, now.month, 1)) : (_to ?? now);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(now.year + 2),
      initialDate: init,
    );
    if (picked != null) {
      setState(() {
        if (from) _from = picked; else _to = picked;
      });
    }
  }

  void _search() {
    int? pid = int.tryParse(_productIdCtrl.text.trim());
    movProv.fetch(
      productId: pid,
      type: _type,
      from: _from,
      to: _to,
      page: 1,
      pageSize: 50,
      sort: 'desc',
    );
  }

  Future<void> _exportCsvOpenBrowser() async {
    final params = <String, String>{};
    if (_productIdCtrl.text.trim().isNotEmpty) params['productId'] = _productIdCtrl.text.trim();
    if (_type != null && _type!.isNotEmpty) params['type'] = _type!;
    if (_from != null) params['from'] = _from!.toIso8601String();
    if (_to != null) params['to'] = _to!.toIso8601String();

    final qs = Uri(queryParameters: params).query;
    final url = 'http://localhost:5001/api/movements/export${qs.isEmpty ? '' : '?$qs'}';

    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible abrir el navegador')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MovementsProvider>();
    final df = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Historial de Movimientos'),
        actions: [
          IconButton(
            tooltip: 'Exportar CSV',
            icon: const Icon(Icons.download),
            onPressed: () {
              _exportCsvOpenBrowser();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _Filters(
            productIdCtrl: _productIdCtrl,
            type: _type,
            onTypeChanged: (v) => setState(() => _type = v),
            from: _from,
            to: _to,
            pickDate: _pickDate,
            onSearch: _search,
          ),

          // Totales
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _TotalChip(label: 'Entradas', value: prov.entradas),
                _TotalChip(label: 'Salidas',  value: prov.salidas),
                _TotalChip(label: 'Ajustes',  value: prov.ajustes),
                _TotalChip(label: 'Balance',  value: prov.balance, bold: true),
              ],
            ),
          ),

          // Encabezados tabla
          Container(
            color: const Color.fromARGB(120, 57, 112, 129),
            child: const Row(
              children: [
                _HeaderCell('Fecha'),
                _HeaderCell('Tipo'),
                _HeaderCell('Cantidad'),
                _HeaderCell('Producto'),
                _HeaderCell('Usuario'),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: prov.loading
                ? const Center(child: CircularProgressIndicator())
                : (prov.error != null)
                    ? Center(child: Text(prov.error!, style: const TextStyle(color: Colors.red)))
                    : (prov.items.isEmpty)
                        ? const Center(child: Text('Sin movimientos'))
                        : ListView.builder(
                            itemCount: prov.items.length,
                            itemBuilder: (context, index) {
                              final it = prov.items[index];
                              return Container(
                                color: index.isEven
                                    ? const Color.fromARGB(120, 135, 180, 194)
                                    : Colors.white,
                                child: Row(
                                  children: [
                                    _DataCell(df.format(it.date)),
                                    _DataCell(it.type),
                                    _DataCell(it.amount),
                                    _DataCell('#${it.productId} — ${it.productName}'),
                                    _DataCell(it.userName ?? '-'),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueGrey.shade900,
        icon: const Icon(Icons.add),
        label: const Text('Registrar movimiento'),
        onPressed: () {
          // Aquí luego conectamos la pantalla para crear IN/OUT/ADJ
           Navigator.push(context, MaterialPageRoute(builder: (_) => CreateMovementScreen()));
        },
      ),
    );
  }
}
/* ---------- Filtros & UI helpers ---------- */

class _Filters extends StatelessWidget {
  final TextEditingController productIdCtrl;
  final String? type;
  final ValueChanged<String?> onTypeChanged;
  final DateTime? from;
  final DateTime? to;
  final Future<void> Function({required bool from}) pickDate;
  final VoidCallback onSearch;

  const _Filters({
    required this.productIdCtrl,
    required this.type,
    required this.onTypeChanged,
    required this.from,
    required this.to,
    required this.pickDate,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    String fmt(DateTime? d) => d == null ? '' : DateFormat('yyyy-MM-dd').format(d);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: TextField(
              controller: productIdCtrl,
              decoration: const InputDecoration(
                labelText: 'ID Producto',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<String>(
              value: type,
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos')),
                DropdownMenuItem(value: 'IN',  child: Text('Entrada')),
                DropdownMenuItem(value: 'OUT', child: Text('Salida')),
                DropdownMenuItem(value: 'ADJ', child: Text('Ajuste')),
              ],
              onChanged: onTypeChanged,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            width: 160,
            child: TextField(
              readOnly: true,
              onTap: () => pickDate(from: true),
              decoration: InputDecoration(
                labelText: 'Desde',
                hintText: 'yyyy-MM-dd',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: const Icon(Icons.date_range),
              ),
              controller: TextEditingController(text: fmt(from)),
            ),
          ),
          SizedBox(
            width: 160,
            child: TextField(
              readOnly: true,
              onTap: () => pickDate(from: false),
              decoration: InputDecoration(
                labelText: 'Hasta',
                hintText: 'yyyy-MM-dd',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: const Icon(Icons.date_range),
              ),
              controller: TextEditingController(text: fmt(to)),
            ),
          ),
          ElevatedButton(
            onPressed: onSearch,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade900),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }
}

class _TotalChip extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  const _TotalChip({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        '$label: ${value.toStringAsFixed(2)}',
        style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String value;
  const _DataCell(this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(value),
      ),
    );
  }
}
