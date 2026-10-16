// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SourceAsset {

 String get path; String get name; String get kind; int get width; int get height; String get thumbnail; int get page; int get pageCount;
/// Create a copy of SourceAsset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SourceAssetCopyWith<SourceAsset> get copyWith => _$SourceAssetCopyWithImpl<SourceAsset>(this as SourceAsset, _$identity);

  /// Serializes this SourceAsset to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SourceAsset&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,name,kind,width,height,thumbnail,page,pageCount);

@override
String toString() {
  return 'SourceAsset(path: $path, name: $name, kind: $kind, width: $width, height: $height, thumbnail: $thumbnail, page: $page, pageCount: $pageCount)';
}


}

/// @nodoc
abstract mixin class $SourceAssetCopyWith<$Res>  {
  factory $SourceAssetCopyWith(SourceAsset value, $Res Function(SourceAsset) _then) = _$SourceAssetCopyWithImpl;
@useResult
$Res call({
 String path, String name, String kind, int width, int height, String thumbnail, int page, int pageCount
});




}
/// @nodoc
class _$SourceAssetCopyWithImpl<$Res>
    implements $SourceAssetCopyWith<$Res> {
  _$SourceAssetCopyWithImpl(this._self, this._then);

  final SourceAsset _self;
  final $Res Function(SourceAsset) _then;

/// Create a copy of SourceAsset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? name = null,Object? kind = null,Object? width = null,Object? height = null,Object? thumbnail = null,Object? page = null,Object? pageCount = null,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,thumbnail: null == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as String,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SourceAsset].
extension SourceAssetPatterns on SourceAsset {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SourceAsset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SourceAsset() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SourceAsset value)  $default,){
final _that = this;
switch (_that) {
case _SourceAsset():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SourceAsset value)?  $default,){
final _that = this;
switch (_that) {
case _SourceAsset() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String name,  String kind,  int width,  int height,  String thumbnail,  int page,  int pageCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SourceAsset() when $default != null:
return $default(_that.path,_that.name,_that.kind,_that.width,_that.height,_that.thumbnail,_that.page,_that.pageCount);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String name,  String kind,  int width,  int height,  String thumbnail,  int page,  int pageCount)  $default,) {final _that = this;
switch (_that) {
case _SourceAsset():
return $default(_that.path,_that.name,_that.kind,_that.width,_that.height,_that.thumbnail,_that.page,_that.pageCount);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String name,  String kind,  int width,  int height,  String thumbnail,  int page,  int pageCount)?  $default,) {final _that = this;
switch (_that) {
case _SourceAsset() when $default != null:
return $default(_that.path,_that.name,_that.kind,_that.width,_that.height,_that.thumbnail,_that.page,_that.pageCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SourceAsset implements SourceAsset {
  const _SourceAsset({required this.path, required this.name, required this.kind, required this.width, required this.height, required this.thumbnail, this.page = 1, this.pageCount = 1});
  factory _SourceAsset.fromJson(Map<String, dynamic> json) => _$SourceAssetFromJson(json);

@override final  String path;
@override final  String name;
@override final  String kind;
@override final  int width;
@override final  int height;
@override final  String thumbnail;
@override@JsonKey() final  int page;
@override@JsonKey() final  int pageCount;

/// Create a copy of SourceAsset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SourceAssetCopyWith<_SourceAsset> get copyWith => __$SourceAssetCopyWithImpl<_SourceAsset>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SourceAssetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SourceAsset&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,name,kind,width,height,thumbnail,page,pageCount);

@override
String toString() {
  return 'SourceAsset(path: $path, name: $name, kind: $kind, width: $width, height: $height, thumbnail: $thumbnail, page: $page, pageCount: $pageCount)';
}


}

/// @nodoc
abstract mixin class _$SourceAssetCopyWith<$Res> implements $SourceAssetCopyWith<$Res> {
  factory _$SourceAssetCopyWith(_SourceAsset value, $Res Function(_SourceAsset) _then) = __$SourceAssetCopyWithImpl;
@override @useResult
$Res call({
 String path, String name, String kind, int width, int height, String thumbnail, int page, int pageCount
});




}
/// @nodoc
class __$SourceAssetCopyWithImpl<$Res>
    implements _$SourceAssetCopyWith<$Res> {
  __$SourceAssetCopyWithImpl(this._self, this._then);

  final _SourceAsset _self;
  final $Res Function(_SourceAsset) _then;

/// Create a copy of SourceAsset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? name = null,Object? kind = null,Object? width = null,Object? height = null,Object? thumbnail = null,Object? page = null,Object? pageCount = null,}) {
  return _then(_SourceAsset(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,thumbnail: null == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as String,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
