import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/data/dummy_data.dart';
import 'package:latest_movies/features/movies/controllers/popular_paginated_movies_provider.dart';
import 'package:latest_movies/features/movies/models/movie/genre.dart';
import 'package:latest_movies/features/movies/models/movie/movie.dart';

import '../../../core/models/paginated_response.dart';

final popularMoviesCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(paginatedPopularMoviesProvider(0)).whenData(
        (PaginatedResponse<Movie> pageData) => pageData.totalResults,
      );
});

// New provider for movies by genre using dummy data
final moviesByGenreProvider = FutureProvider.family<List<Movie>, int>((ref, genreId) async {
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 600));
  
  if (genreId == 0) {
    // Return all movies for "All" genre
    return dummyMovies;
  }
  
  // Filter movies by genre
  return dummyMovies.where((movie) => 
    movie.genres?.any((genre) => genre.id == genreId) ?? false
  ).toList();
});

// Provider for all genres with their movies
final allGenresWithMoviesProvider = FutureProvider<Map<Genre, List<Movie>>>((ref) async {
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 1000));
  
  final Map<Genre, List<Movie>> genreMoviesMap = {};
  
  // Add "All" genre with all movies
  genreMoviesMap[const Genre(id: 0, name: 'All')] = dummyMovies;
  
  // Add each genre with its movies
  for (final genre in dummyGenres) {
    final moviesForGenre = dummyMovies.where((movie) => 
      movie.genres?.any((movieGenre) => movieGenre.id == genre.id) ?? false
    ).toList();
    genreMoviesMap[genre] = moviesForGenre;
  }
  
  return genreMoviesMap;
});
