import 'package:actual/common/const/data.dart';
import 'package:actual/restaurant/model/restaurant_model.dart';

// "detail": "!!!리뷰 EVENT & 비조리 EVENT 진행중!!!\n    \n@ 기본적으로 매콤합니다 @\n@ 덜맵게 가능하니 요청사항에 적어주세요 @\n@ 1인분 배달 가능합니다 @",
// "products": [
// {
// "id": "77491ba3-6351-4635-8b30-c891bf6574ab",
// "name": "떡볶이",
// "detail": "전통 떡볶이의 정석! 원하는대로 맵기를 선택하고 추억의 떡볶이맛에 빠져보세요! 쫀득한 쌀떡과 말랑한 오뎅의 완벽한 조화! 잘익은 반숙 계란은 덤!",
// "imgUrl": "/img/떡볶이/떡볶이.jpg",
// "price": 10000
// },

class RestaurantDetailModel extends RestaurantModel {
  final String detail;
  final List<RestaurantProductModel> products;

  RestaurantDetailModel({
    required super.id,
    required super.name,
    required super.thumbUrl,
    required super.tags,
    required super.priceRange,
    required super.ratings,
    required super.ratingsCount,
    required super.deliveryTime,
    required super.deliveryFee,
    required this.detail,
    required this.products,
  });

  factory RestaurantDetailModel.fromJson({
    required Map<String, dynamic> json,
  }) {
    return RestaurantDetailModel(
      id: json['id'],
      name: json['name'],
      thumbUrl: 'http://$ip${json['thumbUrl']}',
      tags: List<String>.from(json['tags']),
      priceRange: RestaurantPriceRange.values
          .firstWhere((e) => e.name == json['priceRange']),
      ratings: json['ratings'],
      ratingsCount: json['ratingsCount'],
      deliveryTime: json['deliveryTime'],
      deliveryFee: json['deliveryFee'],
      detail: json['detail'],
      products: json['products']
          .map<RestaurantProductModel>(
            (x) => RestaurantProductModel.fromJson(
              json: x,
            ),
          )
          .toList(),
    );
  }
}

class RestaurantProductModel {
  final String id;
  final String name;
  final String detail;
  final String imgUrl;
  final int price;

  RestaurantProductModel({
    required this.id,
    required this.name,
    required this.detail,
    required this.imgUrl,
    required this.price,
  });

  factory RestaurantProductModel.fromJson({
    required Map<String, dynamic> json,
  }) {
    return RestaurantProductModel(
      id: json['id'],
      name: json['name'],
      detail: json['detail'],
      imgUrl: 'http://$ip${json['imgUrl']}',
      price: json['price'],
    );
  }
}
