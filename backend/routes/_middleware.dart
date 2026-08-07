import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/business_logo.dart';
import 'package:inventy_backend/src/application/create_product.dart';
import 'package:inventy_backend/src/application/create_products_bulk.dart';
import 'package:inventy_backend/src/application/create_user.dart';
import 'package:inventy_backend/src/application/delete_product.dart';
import 'package:inventy_backend/src/application/delete_product_image.dart';
import 'package:inventy_backend/src/application/delete_user.dart';
import 'package:inventy_backend/src/application/detect_low_stock.dart';
import 'package:inventy_backend/src/application/find_product_by_code.dart';
import 'package:inventy_backend/src/application/get_product_image.dart';
import 'package:inventy_backend/src/application/get_settings.dart';
import 'package:inventy_backend/src/application/list_movements.dart';
import 'package:inventy_backend/src/application/list_products.dart';
import 'package:inventy_backend/src/application/list_sales.dart';
import 'package:inventy_backend/src/application/list_users.dart';
import 'package:inventy_backend/src/application/login.dart';
import 'package:inventy_backend/src/application/register_sale.dart';
import 'package:inventy_backend/src/application/register_stock_entry.dart';
import 'package:inventy_backend/src/application/register_stock_exit.dart';
import 'package:inventy_backend/src/application/save_product_image.dart';
import 'package:inventy_backend/src/application/update_product.dart';
import 'package:inventy_backend/src/application/update_settings.dart';
import 'package:inventy_backend/src/domain/entities/user.dart';
import 'package:inventy_backend/src/infrastructure/auth/jwt_service.dart';
import 'package:inventy_backend/src/infrastructure/auth/password_hasher.dart';
import 'package:inventy_backend/src/infrastructure/postgres/database.dart';
import 'package:inventy_backend/src/infrastructure/postgres/postgres_low_stock_repository.dart';
import 'package:inventy_backend/src/infrastructure/postgres/postgres_movement_history_repository.dart';
import 'package:inventy_backend/src/infrastructure/postgres/postgres_product_image_repository.dart';
import 'package:inventy_backend/src/infrastructure/postgres/postgres_product_repository.dart';
import 'package:inventy_backend/src/infrastructure/postgres/postgres_sales_repository.dart';
import 'package:inventy_backend/src/infrastructure/postgres/postgres_settings_repository.dart';
import 'package:inventy_backend/src/infrastructure/postgres/postgres_stock_repository.dart';
import 'package:inventy_backend/src/infrastructure/postgres/postgres_user_repository.dart';

final _jwt = JwtService();

/// Dependency injection + auth. Providers are built at the edge; the auth
/// middleware verifies the JWT, exposes the current [User], and enforces roles.
Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(
        provider<Future<CreateProduct>>(
          (_) async => CreateProduct(
            PostgresProductRepository(await Database.connection()),
          ),
        ),
      )
      .use(
        provider<Future<CreateProductsBulk>>(
          (_) async => CreateProductsBulk(
            PostgresProductRepository(await Database.connection()),
          ),
        ),
      )
      .use(
        provider<Future<ListProducts>>(
          (_) async => ListProducts(
            PostgresProductRepository(await Database.connection()),
          ),
        ),
      )
      .use(
        provider<Future<UpdateProduct>>(
          (_) async => UpdateProduct(
            PostgresProductRepository(await Database.connection()),
          ),
        ),
      )
      .use(
        provider<Future<DeleteProduct>>(
          (_) async => DeleteProduct(
            PostgresProductRepository(await Database.connection()),
          ),
        ),
      )
      .use(
        provider<Future<FindProductByCode>>(
          (_) async => FindProductByCode(
            PostgresProductRepository(await Database.connection()),
          ),
        ),
      )
      .use(
        provider<Future<RegisterStockEntry>>(
          (_) async => RegisterStockEntry(
            PostgresStockRepository(await Database.connection()),
          ),
        ),
      )
      .use(
        provider<Future<RegisterStockExit>>(
          (_) async => RegisterStockExit(
            PostgresStockRepository(await Database.connection()),
          ),
        ),
      )
      .use(
        provider<Future<DetectLowStock>>(
          (_) async => DetectLowStock(
            PostgresLowStockRepository(await Database.connection()),
          ),
        ),
      )
      .use(
        provider<Future<ListMovements>>(
          (_) async => ListMovements(
            PostgresMovementHistoryRepository(await Database.connection()),
          ),
        ),
      )
      .use(
        provider<Future<RegisterSale>>(
          (_) async => RegisterSale(
            PostgresSalesRepository(await Database.connection()),
            PostgresStockRepository(await Database.connection()),
          ),
        ),
      )
      .use(
        provider<Future<ListSales>>(
          (_) async =>
              ListSales(PostgresSalesRepository(await Database.connection())),
        ),
      )
      .use(
        provider<Future<SaveProductImage>>(
          (_) async => SaveProductImage(
            PostgresProductImageRepository(await Database.connection()),
          ),
        ),
      )
      .use(
        provider<Future<GetProductImage>>(
          (_) async => GetProductImage(
            PostgresProductImageRepository(await Database.connection()),
          ),
        ),
      )
      .use(
        provider<Future<DeleteProductImage>>(
          (_) async => DeleteProductImage(
            PostgresProductImageRepository(await Database.connection()),
          ),
        ),
      )
      .use(
        provider<Future<GetSettings>>(
          (_) async => GetSettings(
            PostgresSettingsRepository(await Database.connection()),
          ),
        ),
      )
      .use(
        provider<Future<UpdateSettings>>(
          (_) async => UpdateSettings(
            PostgresSettingsRepository(await Database.connection()),
          ),
        ),
      )
      .use(
        provider<Future<GetBusinessLogo>>(
          (_) async => GetBusinessLogo(
            PostgresSettingsRepository(await Database.connection()),
          ),
        ),
      )
      .use(
        provider<Future<SaveBusinessLogo>>(
          (_) async => SaveBusinessLogo(
            PostgresSettingsRepository(await Database.connection()),
          ),
        ),
      )
      .use(
        provider<Future<DeleteBusinessLogo>>(
          (_) async => DeleteBusinessLogo(
            PostgresSettingsRepository(await Database.connection()),
          ),
        ),
      )
      .use(
        provider<Future<Login>>(
          (_) async => Login(
            PostgresUserRepository(await Database.connection()),
            PasswordHasher(),
            _jwt,
          ),
        ),
      )
      .use(
        provider<Future<CreateUser>>(
          (_) async => CreateUser(
            PostgresUserRepository(await Database.connection()),
            PasswordHasher(),
          ),
        ),
      )
      .use(
        provider<Future<ListUsers>>(
          (_) async =>
              ListUsers(PostgresUserRepository(await Database.connection())),
        ),
      )
      .use(
        provider<Future<DeleteUser>>(
          (_) async =>
              DeleteUser(PostgresUserRepository(await Database.connection())),
        ),
      )
      .use(_auth())
      .use(_cors());
}

// --- Auth ---------------------------------------------------------------

/// Public routes (no token needed): login, and the business name + logo the
/// login screen shows before authenticating.
bool _isPublic(RequestContext context) {
  final m = context.request.method;
  if (m == HttpMethod.options) return true;
  final p = context.request.uri.path;
  if (m == HttpMethod.post && p == '/auth/login') return true;
  if (m == HttpMethod.get && (p == '/settings' || p == '/settings/logo')) {
    return true;
  }
  return false;
}

/// Owner-only routes. Everything not listed is available to any logged-in user
/// (e.g. employees: GET products, register sales, product images).
bool _isOwnerOnly(RequestContext context) {
  final m = context.request.method;
  final p = context.request.uri.path;
  if (p == '/users' || p.startsWith('/users/')) return true;
  if (m != HttpMethod.get && (p == '/settings' || p.startsWith('/settings/'))) {
    return true;
  }
  if (p == '/products' && m == HttpMethod.post) return true;
  if (p.startsWith('/products/') && m != HttpMethod.get) return true;
  if (p == '/movements' || p.startsWith('/movements/')) return true;
  if (p == '/alerts' || p.startsWith('/alerts/')) return true;
  if (p == '/sales' && m == HttpMethod.get) return true;
  if (p.startsWith('/sales/series')) return true;
  return false;
}

User? _currentUser(RequestContext context) {
  final auth = context.request.headers['authorization'] ??
      context.request.headers['Authorization'];
  if (auth == null || !auth.startsWith('Bearer ')) return null;
  return _jwt.verify(auth.substring(7));
}

Middleware _auth() {
  return (handler) {
    return (context) async {
      final user = _currentUser(context);
      final ctx = context.provide<User?>(() => user);
      if (_isPublic(context)) return handler(ctx);
      if (user == null) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {'error': 'No autenticado'},
        );
      }
      if (_isOwnerOnly(context) && !user.isOwner) {
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {'error': 'Solo el dueño puede hacer esto'},
        );
      }
      return handler(ctx);
    };
  };
}

// --- CORS (outermost, so 401/403 also carry the headers) ----------------

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

Middleware _cors() {
  return (handler) {
    return (context) async {
      if (context.request.method == HttpMethod.options) {
        return Response(statusCode: HttpStatus.ok, headers: _corsHeaders);
      }
      final response = await handler(context);
      return response.copyWith(
        headers: {...response.headers, ..._corsHeaders},
      );
    };
  };
}
