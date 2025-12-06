const eitherTemplate = r'''
/// Simple Either implementation
abstract class Either<L, R> {
  const Either();
  B fold<B>(B Function(L l) leftF, B Function(R r) rightF);
}

class Left<L, R> extends Either<L, R> {
  const Left(this.value);
  final L value;
  @override
  B fold<B>(B Function(L l) leftF, B Function(R r) rightF) => leftF(value);
}

class Right<L, R> extends Either<L, R> {
  const Right(this.value);
  final R value;
  @override
  B fold<B>(B Function(L l) leftF, B Function(R r) rightF) => rightF(value);
}
''';

const serviceLocatorTemplate = r'''
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

/// Initialize your service locator and call private _register...() functions here.
Future<void> initServiceLocator() async {
  // register core services here, and calls to private _registerXService() functions
}
''';

const routesTemplate = r'''
import 'package:flutter/material.dart';

class AppRoutes {
  static const home = '/';
}

Route<dynamic>? generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.home:
      return MaterialPageRoute(builder: (_) => const _HomeScreen());
    default:
      return MaterialPageRoute(builder: (_) => const _ErrorScreen());
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Error: Route not found')));
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Welcome')));
  }
}
''';

const appThemeTemplate = r'''
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() => ThemeData.light().copyWith();
  static ThemeData dark() => ThemeData.dark().copyWith();
}
''';

const mainTemplateWithSl = r'''
import 'package:flutter/material.dart';
import 'package:$project/core/routes/app_routes.dart';
import 'package:$project/core/service_locator/service_locator.dart';
import 'package:$project/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MVVM App',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      onGenerateRoute: generateRoute,
      initialRoute: AppRoutes.home,
    );
  }
}
''';

const mvvmReadmeTemplate = '''
# MVVM scaffolding

This project was prepared by mvvm CLI tool.
- Features go inside lib/features/<feature>/
- Models: lib/data/models/
- Repos: lib/data/repos/
- Services: lib/data/services/
- Service locator: lib/core/service_locator/service_locator.dart

Run:
  flutter pub get
  flutter pub run build_runner build --delete-conflicting-outputs
''';

const mvvmAnalysisTemplate = '''
include: package:very_good_analysis/analysis_options.yaml
linter:
  rules:
    public_member_api_docs: false
analyzer:
  errors:
    one_member_abstracts: ignore
''';

final String viewUsingValueNotifierTemplate(String feature, String className) => '''
import 'package:flutter/material.dart';
import './${feature}_viewmodel.dart';

class ${className}View extends StatelessWidget {
  ${className}View({super.key});

  final ${className}ViewModel viewModel = ${className}ViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('${className}')),
      body: Center(
        child: ValueListenableBuilder<bool>(
          valueListenable: viewModel.isLoading,
          builder: (context, isLoading, child) => isLoading 
            ? const CircularProgressIndicator() 
            : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: viewModel.load,
                  child: const Text('Hello from ${className}View!'),
                ),
              ],
            ),
        ),
      ),
    );
  }
}
''';

final String viewModelValueNotifierTemplate(String feature, String className) => '''
import 'package:flutter/foundation.dart';

class ${className}ViewModel {
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  Future<void> load() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    isLoading.value = false;
  }
}
''';

final String repoTemplate(String name, String className) => '''
abstract interface class ${className}Repo {
  ${className}Repo();

  Future<List<dynamic>> fetchAll();
}
''';

final String serviceTemplate(String name, String className) => '''
import '../repos/${name}_repo.dart';

class ${className}Service implements ${className}Repo {
  ${className}Service();

  @override
  Future<List<dynamic>> fetchAll() async {
    // implement your service logic here
    return [];
  }
}
''';

final String modelJsonTemplate(String name, String className) => '''
import 'package:json_annotation/json_annotation.dart';

part '${name}_model.g.dart';

@JsonSerializable()
class ${className}Model {
  const ${className}Model({
    required this.id,
    required this.name,
  });

  factory ${className}Model.fromJson(Map<String, dynamic> json) 
          => _\\$${className}ModelFromJson(json);

  final String id;
  final String name;

  Map<String, dynamic> toJson() => _\\$${className}ModelToJson(this);
}
''';