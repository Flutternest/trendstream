import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String? imageUrl;

  const CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, name, imageUrl];

  @override
  String toString() =>
      'CategoryModel(id: $id, name: $name, imageUrl: $imageUrl)';
}

List<CategoryModel> testCategories = [
  const CategoryModel(
      id: '1',
      name: 'Action',
      imageUrl:
          'https://images.unsplash.com/photo-1601933471623-c4d3c5c0dc2f?w=800'),
  const CategoryModel(
      id: '2',
      name: 'Comedy',
      imageUrl:
          'https://images.unsplash.com/photo-1598899134739-24c46f58b8b4?w=800'),
  const CategoryModel(
      id: '3',
      name: 'Drama',
      imageUrl:
          'https://images.unsplash.com/photo-1587502536263-9298c3ccf2fd?w=800'),
  const CategoryModel(
      id: '4',
      name: 'Horror',
      imageUrl:
          'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800'),
  const CategoryModel(
      id: '5',
      name: 'Sci-Fi',
      imageUrl:
          'https://images.unsplash.com/photo-1604079628040-943ad1b3f00b?w=800'),
  const CategoryModel(
      id: '6',
      name: 'Romance',
      imageUrl:
          'https://images.unsplash.com/photo-1517849845537-4d257902454a?w=800'),
  const CategoryModel(
      id: '7',
      name: 'Thriller',
      imageUrl:
          'https://images.unsplash.com/photo-1607532941433-48b23d2d1b3f?w=800'),
  const CategoryModel(
      id: '8',
      name: 'Adventure',
      imageUrl:
          'https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=800'),
  const CategoryModel(
      id: '9',
      name: 'Fantasy',
      imageUrl:
          'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800'),
  const CategoryModel(
      id: '10',
      name: 'Mystery',
      imageUrl:
          'https://images.unsplash.com/photo-1523413651479-597eb2da0ad6?w=800'),
  const CategoryModel(
      id: '11',
      name: 'Animation',
      imageUrl:
          'https://images.unsplash.com/photo-1593697820873-0c59d6c308ed?w=800'),
  const CategoryModel(
      id: '12',
      name: 'Documentary',
      imageUrl:
          'https://images.unsplash.com/photo-1581090700227-1e8f8f41c116?w=800'),
  const CategoryModel(
      id: '13',
      name: 'Family',
      imageUrl:
          'https://images.unsplash.com/photo-1607746882042-944635dfe10e?w=800'),
  const CategoryModel(
      id: '14',
      name: 'History',
      imageUrl:
          'https://images.unsplash.com/photo-1569163553936-1f46d77682e4?w=800'),
];
