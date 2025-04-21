// search_dialog.dart - Диалог для поиска допуска
// Позволяет пользователю найти нужный допуск по названию

import 'package:flutter/material.dart';

// Функция для отображения диалога поиска допуска
Future<String?> showSearchDialog(
  BuildContext context, 
  List<String> tolerances,
) async {
  // Контроллер для текстового поля
  final TextEditingController controller = TextEditingController();
  
  // Список отфильтрованных допусков
  List<String> filteredTolerances = List.from(tolerances);
  
  // Результат, выбранный пользователем
  String? selectedTolerance;
  
  // Показываем диалог и ждем результат
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          // Фильтрация списка допусков по введенному тексту
          void filterTolerances(String query) {
            setState(() {
              if (query.isEmpty) {
                filteredTolerances = List.from(tolerances);
              } else {
                filteredTolerances = tolerances
                    .where((tolerance) => 
                        tolerance.toLowerCase().contains(query.toLowerCase()))
                    .toList();
              }
            });
          }
          
          // Виджет, отображающий пояснение о значках
          
          
          return AlertDialog(
            title: const Text('Поиск допуска'),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(
                maxHeight: 400,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Поле ввода для поиска
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Введите обозначение допуска',
                      hintText: 'например: h7, H8, k6',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: filterTolerances,
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  
                  // Список результатов
                  Expanded(
                    child: filteredTolerances.isEmpty
                        ? const Center(
                            child: Text('Нет результатов',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredTolerances.length,
                            itemBuilder: (context, index) {
                              final tolerance = filteredTolerances[index];
                              return ListTile(
                                title: Text(tolerance),
                                // Определяем значок в зависимости от регистра первой буквы
                                leading: Icon(
                                  tolerance[0] == tolerance[0].toUpperCase()
                                      ? Icons.add_circle  // отверстие (H) - внутренний размер "+"
                                      : Icons.remove_circle,  // вал (h) - внешний размер "-"
                                  color: tolerance[0] == tolerance[0].toUpperCase()
                                      ? Colors.blue  // отверстие
                                      : Colors.red,  // вал
                                ),
                                // Добавляем дополнительную подсказку справа
                                trailing: Text(
                                  tolerance[0] == tolerance[0].toUpperCase()
                                      ? 'Отверстие'
                                      : 'Вал',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                onTap: () {
                                  selectedTolerance = tolerance;
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Отмена'),
              ),
            ],
          );
        },
      );
    },
  );
  
  return selectedTolerance;
}