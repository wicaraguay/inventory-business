import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inventy_backend/src/application/create_product.dart';
import 'package:inventy_backend/src/application/create_products_bulk.dart';
import 'package:inventy_backend/src/application/delete_product.dart';
import 'package:inventy_backend/src/application/delete_product_image.dart';
import 'package:inventy_backend/src/application/detect_low_stock.dart';
import 'package:inventy_backend/src/application/get_product_image.dart';
import 'package:inventy_backend/src/application/get_settings.dart';
import 'package:inventy_backend/src/application/find_product_by_code.dart';
import 'package:inventy_backend/src/application/list_movements.dart';
import 'package:inventy_backend/src/application/list_products.dart';
import 'package:inventy_backend/src/application/list_sales.dart';
import 'package:inventy_backend/src/application/register_sale.dart';
import 'package:inventy_backend/src/application/register_stock_entry.dart';
import 'package:inventy_backend/src/application/register_stock_exit.dart';
import 'package:inventy_backend/src/application/save_product_image.dart';
import 'package:inventy_backend/src/application/update_product.dart';
import 'package:inventy_backend/src/application/update_settings.dart';
import 'package:inventy_backend/src/infrastructure/postgres/database.dart';
import 'package:inventy_backend/src/infrastructure/postgres/postgres_low_stock_repository.dart';
import 'package:inventy_backend/src/infrastructure/postgres/postgres_product_image_repository.dart';
import 'package:inventy_backend/src/infrastructure/postgres/postgres_movement_history_repository.dart';
import 'package:inventy_backend/src/infrastructure/postgres/postgres_product_repository.dart';
import 'package:inventy_backend/src/infrastructure/postgres/postgres_sales_repository.dart';
import 'package:inventy_backend/src/infrastructure/postgres/postgres_settings_repository.dart';
import 'package:inventy_backend/src/infrastructure/postgres/postgres_stock_repository.dart';

/// Dependency injection wiring. The connection is a cached singleton, so each
/// provider can await it cheaply. Adapters are built here, at the edge.
Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(_cors())
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
          (_) async => ListSales(
            PostgresSalesRepository(await Database.connection()),
          ),
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
      );
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

/// Allows the Flutter web client (different origin) to call the API, and
/// answers CORS preflight (OPTIONS) requests.
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
