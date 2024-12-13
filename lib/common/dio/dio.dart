import 'package:actual/common/const/data.dart';
import 'package:actual/common/secure_storage/secure_storage.dart';
import 'package:actual/user/provider/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();

  final storage = ref.watch(secureStorageProvider);

  dio.interceptors.add(
    CustomInterceptor(
      storage: storage,
      ref: ref,
    ),
  );

  return dio;
});

class CustomInterceptor extends Interceptor {
  final FlutterSecureStorage storage;
  final Ref ref;

  CustomInterceptor({
    required this.storage,
    required this.ref,
  });

  // 1) 요청 보낼 때
  // 요청이 보내질 때 마다 요청의 header에 accessToken: ture라는 값이 있다면
  // 실제 토큰을 가져와서 (storage) authorization: bearer $token으로 헤더를 변경한다.
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // print(
    //   '[REQ][${options.method} ${options.uri}]',
    // );
    if (options.headers['accessToken'] == 'true') {
      // 헤더 삭제
      options.headers.remove('accessToken');

      final token = await storage.read(key: ACCESS_TOKEN_KEY);

      // 실제 토큰으로 대체
      options.headers.addAll({'authorization': 'Bearer $token'});
    }

    if (options.headers['refreshToken'] == 'true') {
      // 헤더 삭제
      options.headers.remove('refreshToken');

      final token = await storage.read(key: REFRESH_TOKEN_KEY);

      // 실제 토큰으로 대체
      options.headers.addAll({'authorization': 'Bearer $token'});
    }

    return super.onRequest(options, handler);
  }

  // 2) 응답을 받을 때
  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    // print(
    //   '[RES][${response.requestOptions.method} ${response.requestOptions.uri}]',
    // );

    return super.onResponse(response, handler);
  }

  // 3) 에러가 났을 때
  @override
  void onError(
    DioError err,
    ErrorInterceptorHandler handler,
  ) async {
    // 401 에러가 발생했을 때 (status code)
    // 토큰을 재발급 받는 시도를 하고 토큰이 재발급되면 새로운 토큰으로 다시 요청한다.
    print(
      '[ERR][${err.requestOptions.method} ${err.requestOptions.uri}]',
    );

    final refreshToken = await storage.read(key: REFRESH_TOKEN_KEY);

    // refreshToken이 아예 없으면 에러를 던진다.
    if (refreshToken == null) {
      return handler.reject(err);
    }

    final isStatus401 = err.response?.statusCode == 401;
    final isPathRefresh = err.requestOptions.path == '/auth/token';

    if (isStatus401 && !isPathRefresh) {
      final dio = Dio();

      try {
        final resp = await dio.post(
          'http://$ip/auth/token',
          options: Options(
            headers: {
              'authorization': 'Bearer $refreshToken',
            },
          ),
        );

        final accessToken = resp.data['accessToken'];

        final options = err.requestOptions;

        // 토큰 변경
        options.headers.addAll({
          'authorization': 'Bearer $accessToken',
        });

        await storage.write(key: ACCESS_TOKEN_KEY, value: accessToken);

        // 요청 재전송
        final response = await dio.fetch(options);
        // 응답값을 넣어주면 실제로 요청을 실행한 화면에서는 에러가 나지 않은 것처럼 인식 가능
        return handler.resolve(response);
      } on DioError catch (e) {
        // 아래 에러: circular dependency error
        // dio와 userMeProvider가 서로를 필요로 하기때문에 무한 로딩이 생김
        // ref.read(userMeProvider.notifier).logout();

        ref.read(authProvider.notifier).logout();

        return handler.reject(e);
      }
    }

    return handler.reject(err);
  }
}
