import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surf_test/modules/main_page/data/model/movies_model.dart';
import 'package:surf_test/modules/main_page/domain/entity/movies_entity.dart';
import 'package:surf_test/modules/main_page/domain/usecases/get_movies_usecase.dart';
import 'package:surf_test/modules/main_page/domain/usecases/search_movies_usecase.dart';

part 'movie_event.dart';
part 'movie_state.dart';

// void getFromCache() async {
//   final SharedPreferences prefs = await SharedPreferences.getInstance();

//   // Fetch and decode data
//   final String? moviesString = await prefs.getString('movies');

//   final List<MoviesEntity> musics = MoviesModel.decode(moviesString!);
// }

// void saveToCace(List<MoviesEntity> musics) async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();

//   // Encode and store data in SharedPreferences
//   final String encodedData = MoviesModel.encode(musics);

//   await prefs.setString('movies', encodedData);
// }

class MovieBloc extends Bloc<MovieEvent, MovieState> {
  final GetMovies getMovies;
  final SearchMovies searchMovies;
  int page = 1;
  int searchPage = 1;
  bool isFetching = false;
  MovieBloc(this.getMovies, this.searchMovies) : super(MovieInitial());

  @override
  Stream<MovieState> mapEventToState(MovieEvent event) async* {
    if (event is LoadMovies) {
      try {
        final response = await getMovies(GetMoviesParams(page: page));

        yield response.fold((failure) => MovieFailure(failure.toString()),
            (movies) {
          page++;
          return MovieLoadSuccess(movies);
        });
      } on DioError catch (e) {
        print(e.response!.statusCode);
        yield MovieFailure('Server Error!');
      } catch (e) {
        yield MovieFailure(e.toString());
      }
    }
    if (event is UpdateMovies) {
      yield MovieLoading();
      try {
        final response = await getMovies(GetMoviesParams(page: 1));

        yield response.fold(
          (failure) => MovieFailure(failure.toString()),
          (movies) => MovieLoadSuccess(movies),
        );
      } on DioError catch (e) {
        print(e.response!.statusCode);
        yield MovieFailure('Server Error!');
      } catch (e) {
        yield MovieFailure(e.toString());
      }
    }
    if (event is SearchMovie) {
      yield MovieLoading();
      try {
        final response = await searchMovies(
            SearchMoviesParams(page: searchPage, query: event.query));
        print('Search Reponse $response');
        yield response.fold((failure) => MovieFailure(failure.toString()),
            (movies) {
          return SearchSuccess(movies);
        });
      } on DioError catch (e) {
        print(e.response!.statusCode);
        yield MovieFailure('Server Error!');
      } catch (e) {
        yield MovieFailure(e.toString());
      }
    }
    if (event is SaveToCache) {
      bool saveCheck = false;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String encodedData = MoviesModel.encode(event.musics);
      saveCheck = await prefs.setString('movies', encodedData);

      if (saveCheck != false) {
        yield SavedToCacheSuccess();
      } else {
        yield MovieFailure('Не получилось сохранить');
      }
    }
    if (event is GetFromCache) {
     final SharedPreferences prefs = await SharedPreferences.getInstance();
     // ignore: await_only_futures
     final String? moviesString = await prefs.getString('movies');
     final List<MoviesEntity>? movies = MoviesModel.decode(moviesString!);

      if (movies != null) {
        yield GetFromCacheSuccess(movies);
      } else {
        yield MovieFailure('Ошибка вывода с кэша');
      }
    }
  }
}
