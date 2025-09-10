import 'package:flutter/material.dart';
import 'package:erpraf/widgets/popupMenu.dart';

class ListInventoryScreen extends StatelessWidget {
  ListInventoryScreen({super.key});
  final List<Map<String, String>> inventoryData = [
    {
      'codigo': '025638',
      'nombre': 'Playera Am',
      'categoria': 'ROPA',
      'marca': 'Pirma',
      'talla': 'Mediana',
      'stockMin': '20',
      'existencia': '15',
      'precio': '\$1500',
      'color': 'Amarillo',
      'ubicacion': 'B23',
    },
    {
      'codigo': '145789',
      'nombre': 'Tenis Rojo',
      'categoria': 'CALZADO',
      'marca': 'Nike',
      'talla': '8 MX',
      'stockMin': '10',
      'existencia': '12',
      'precio': '\$2200',
      'color': 'Rojo',
      'ubicacion': 'A15',
    },
    {
      'codigo': '456321',
      'nombre': 'Sudadera Negra',
      'categoria': 'ROPA',
      'marca': 'Adidas',
      'talla': 'Grande',
      'stockMin': '5',
      'existencia': '7',
      'precio': '\$1800',
      'color': 'Negro',
      'ubicacion': 'C01',
    },
    {
      'codigo': '785412',
      'nombre': 'Gorra Azul',
      'categoria': 'ACCESORIO',
      'marca': 'Puma',
      'talla': 'Única',
      'stockMin': '8',
      'existencia': '10',
      'precio': '\$500',
      'color': 'Azul',
      'ubicacion': 'D09',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Listado de Inventario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar codigo',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade900),
                  child: const Text('Buscar codigo'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade900),
                  child: const Text('Descargar reporte'),
                ),
              ],
            ),
          ),
          Container(
            color: const Color.fromARGB(120, 57, 112, 129),
            child: const Row(
              children: [
                _HeaderCell('Codigo'),
                _HeaderCell('Nombre'),
                _HeaderCell('Categoria'),
                _HeaderCell('Marca'),
                _HeaderCell('Talla'),
                _HeaderCell('Stock minimo'),
                _HeaderCell('Existencia'),
                _HeaderCell('Precio'),
                _HeaderCell(''),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: inventoryData.length,
              itemBuilder: (context, index) {
                final item = inventoryData[index];
                return Container(
                  color: index % 2 == 0
                      ? const Color.fromARGB(120, 135, 180, 194)
                      : Colors.white,
                  child: Row(
                    children: [
                      _DataCell(item['codigo'] ?? ''),
                      _DataCell(item['nombre'] ?? ''),
                      _DataCell(item['categoria'] ?? ''),
                      _DataCell(item['marca'] ?? ''),
                      _DataCell(item['talla'] ?? ''),
                      _DataCell(item['stockMin'] ?? ''),
                      _DataCell(item['existencia'] ?? ''),
                      _DataCell(item['precio'] ?? ''),
                      _OptionsMenu(
                        onSelected: (option) {
                          switch (option) {
                            case 'editar':
                              _showEditDialog(context, item);
                              break;

                            case 'eliminar':
                              _showDeleteDialog(context, () {
                                inventoryData.removeAt(index);
                                setState(() {});
                              });

                              break;
                            case 'detalles':
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text('Detalle de #${item['codigo']}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildDetailRow('Nombre', item['nombre']),
                                      _buildDetailRow(
                                          'Categoria', item['categoria']),
                                      _buildDetailRow('Marca', item['marca']),
                                      _buildDetailRow('Talla', item['talla']),
                                      _buildDetailRow(
                                          'Stock mínimo', item['stockMin']),
                                      _buildDetailRow(
                                          'Existencia', item['existencia']),
                                      _buildDetailRow('Precio', item['precio']),
                                      _buildDetailRow('Color', item['color']),
                                      _buildDetailRow(
                                          'Ubicación', item['ubicacion']),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text('Cerrar'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              );
                              break;
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void setState(Null Function() param0) {}
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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

void _showEditDialog(BuildContext context, Map<String, String> item) {
  final nombreCtrl = TextEditingController(text: item['nombre']);
  final categoriaCtrl = TextEditingController(text: item['categoria']);
  final marcaCtrl = TextEditingController(text: item['marca']);
  final tallaCtrl = TextEditingController(text: item['talla']);
  final stockMinCtrl = TextEditingController(text: item['stockMin']);
  final existenciaCtrl = TextEditingController(text: item['existencia']);
  final precioCtrl = TextEditingController(text: item['precio']);
  final colorCtrl = TextEditingController(text: item['color']);
  final ubicacionCtrl = TextEditingController(text: item['ubicacion']);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Editar producto #${item['codigo']}'),
      content: SingleChildScrollView(
        child: Container(
          width: 600, 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditField('Nombre', nombreCtrl),
              _buildEditField('Categoría', categoriaCtrl),
              _buildEditField('Marca', marcaCtrl),
              _buildEditField('Talla', tallaCtrl),
              _buildEditField('Stock mínimo', stockMinCtrl),
              _buildEditField('Existencia', existenciaCtrl),
              _buildEditField('Precio', precioCtrl),
              _buildEditField('Color', colorCtrl),
              _buildEditField('Ubicación', ubicacionCtrl),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          onPressed: () {
            item['nombre'] = nombreCtrl.text;
            item['categoria'] = categoriaCtrl.text;
            item['marca'] = marcaCtrl.text;
            item['talla'] = tallaCtrl.text;
            item['stockMin'] = stockMinCtrl.text;
            item['existencia'] = existenciaCtrl.text;
            item['precio'] = precioCtrl.text;
            item['color'] = colorCtrl.text;
            item['ubicacion'] = ubicacionCtrl.text;

            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey.shade900,
          ),
          child: const Text('Guardar cambios'),
        ),
      ],
    ),
  );
}

Widget _buildEditField(String label, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );
}

class _OptionsMenu extends StatelessWidget {
  final void Function(String) onSelected;
  const _OptionsMenu({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_horiz),
        onSelected: onSelected,
        itemBuilder: (BuildContext context) => [
          const PopupMenuItem(value: 'editar', child: Text('Editar')),
          const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
          const PopupMenuItem(value: 'detalles', child: Text('Detalles')),
        ],
      ),
    );
  }
}

Widget _buildDetailRow(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 14),
        children: [
          TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: value ?? ''),
        ],
      ),
    ),
  );
}

void _showDeleteDialog(BuildContext context, VoidCallback onConfirm) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('¿Eliminar registro?'),
      content: const Text(
          '¿Estás seguro que quieres eliminar el registro de inventario?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade800,
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Cierra el diálogo
            onConfirm(); // Ejecuta la función que borra
          },
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
}
