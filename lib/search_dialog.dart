// search_dialog.dart - Диалог для поиска допуска
// Позволяет пользователю найти нужный допуск по названию

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Константы для ключей SharedPreferences
const String _keySearchHistory = 'searchHistory'; // Ключ для истории поиска

// Функция для отображения диалога поиска допуска с учетом истории
Future<String?> showSearchDialog(
  BuildContext context, 
  List<String> tolerances,
) async {
  // Контроллер для текстового поля
  final TextEditingController controller = TextEditingController();
  
  // Загружаем историю поиска
  final List<String> searchHistory = await _loadSearchHistory();
  
  // Сортируем список допусков: сначала недавно использованные, затем остальные
  List<String> sortedTolerances = _sortTolerancesByHistory(tolerances, searchHistory);
  
  // Список отфильтрованных допусков (изначально показываем все)
  List<String> filteredTolerances = List.from(sortedTolerances);
  
  // Результат, выбранный пользователем
  String? selectedTolerance;
  
  // Показываем диалог и ждем результат
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          // Фильтрация списка допусков по введенному тексту, сохраняя сортировку по истории
          void filterTolerances(String query) {
            setState(() {
              if (query.isEmpty) {
                // Если поиск пустой, показываем полный отсортированный список
                filteredTolerances = List.from(sortedTolerances);
              } else {
                // Фильтруем с учетом регистра, сохраняя приоритет истории
                List<String> historyFiltered = searchHistory
                    .where((tolerance) => 
                        tolerance.contains(query) &&
                        tolerances.contains(tolerance))
                    .toList();
                
                List<String> otherFiltered = tolerances
                    .where((tolerance) => 
                        tolerance.contains(query) &&
                        !searchHistory.contains(tolerance))
                    .toList();
                
                // Объединяем результаты: сначала из истории, потом остальные
                filteredTolerances = [...historyFiltered, ...otherFiltered];
              }
            });
          }
          
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
                              final bool isRecent = searchHistory.contains(tolerance);
                              
                              return ListTile(
                                title: Text(tolerance),
                                // Показываем только значок истории
                                leading: isRecent 
                                  ? Icon(
                                      Icons.history,
                                      color: Colors.grey,
                                    )
                                  : SizedBox(width: 8),
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
                                  
                                  // Сохраняем выбранный допуск в историю
                                  _saveToSearchHistory(tolerance);
                                  
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

// Загрузка истории поиска из SharedPreferences
Future<List<String>> _loadSearchHistory() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? history = prefs.getStringList(_keySearchHistory);
    return history ?? [];
  } catch (e) {
    debugPrint('Ошибка при загрузке истории поиска: $e');
    return [];
  }
}

// Сохранение допуска в историю поиска
Future<void> _saveToSearchHistory(String tolerance) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = await _loadSearchHistory();
    
    // Удаляем допуск из списка, если он уже существует
    history.remove(tolerance);
    
    // Добавляем допуск в начало списка (самый недавно использованный)
    history.insert(0, tolerance);
    
    // Ограничиваем размер истории (например, до 10 элементов)
    if (history.length > 10) {
      history = history.sublist(0, 10);
    }
    
    // Сохраняем обновленную историю
    await prefs.setStringList(_keySearchHistory, history);
  } catch (e) {
    debugPrint('Ошибка при сохранении истории поиска: $e');
  }
}

// Сортировка допусков: сначала из истории, затем остальные
List<String> _sortTolerancesByHistory(List<String> tolerances, List<String> history) {
  // Фильтруем историю, оставляя только существующие допуски
  List<String> validHistory = history.where((item) => tolerances.contains(item)).toList();
  
  // Создаем список допусков, которых нет в истории
  List<String> remainingTolerances = tolerances.where((item) => !validHistory.contains(item)).toList();
  
  // Сортируем оставшиеся допуски по алфавиту
  remainingTolerances.sort();
  
  // Объединяем два списка: сначала история, потом остальные
  return [...validHistory, ...remainingTolerances];
}