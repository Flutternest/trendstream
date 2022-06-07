import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latest_movies/shared/text_field.dart';
import 'package:latest_movies/utilities/design_utility.dart';
import 'package:latest_movies/utils/responsive.dart';

import 'auth/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Latest Movies',
        theme: ThemeData.dark().copyWith(
            appBarTheme: Theme.of(context)
                .appBarTheme
                .copyWith(color: Colors.grey[900])),
        home: const LoginView(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    double cardWidth = MediaQuery.of(context).size.width / 10;
    double cardHeight = MediaQuery.of(context).size.width / 5;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        actions: [
          GestureDetector(
            onTap: () {},
            child: const CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage("https://i.pravatar.cc/300"),
            ),
          ),
          const SizedBox(width: 10),
        ],
        title: Row(
          children: [
            const FlutterLogo(),
            horizontalSpaceMedium,
            SizedBox(
              width: MediaQuery.of(context).size.width / 3,
              child: const AppTextField(
                prefixIcon: Icon(Icons.search),
              ),
            )
          ],
        ),
      ),
      body: Row(
        children: <Widget>[
          Expanded(
              flex: 2,
              child: FocusTraversalGroup(child: const DashboardSideBar())),
          horizontalSpaceMedium,
          Expanded(
            flex: 8,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: GridView.builder(
                key: GlobalKey(debugLabel: "dashboardGrid"),
                controller: ScrollController(),
                itemCount: 30,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ResponsiveWidget.isMediumScreen(context)
                      ? 4
                      : ResponsiveWidget.isSmallScreen(context)
                          ? 2
                          : 6,
                  childAspectRatio: cardWidth / cardHeight,
                  mainAxisSpacing: 10.0,
                  crossAxisSpacing: 10.0,
                ),
                itemBuilder: (BuildContext context, int index) {
                  return const Focus(autofocus: true, child: MovieTile());
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MovieTile extends StatelessWidget {
  const MovieTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    /// Get the [BuildContext] of the currently-focused
    /// input field anywhere in the entire widget tree.
    final focusedCtx = FocusManager.instance.primaryFocus!.context;

    /// If u call [ensureVisible] while the keyboard is moving up
    /// (the keyboard's display animation does not yet finish), this
    /// will not work. U have to wait for the keyboard to be fully visible
    Future.delayed(const Duration(milliseconds: 400))
        .then((_) => Scrollable.ensureVisible(
              focusedCtx!,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeIn,
            ));
    return GestureDetector(
      onTap: () {
        Focus.of(context).requestFocus();
      },
      child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.0),
          color: Focus.of(context).hasPrimaryFocus
              ? Colors.white
              : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(.4),
                    blurRadius: 5,
                    spreadRadius: 1,
                    offset: Offset(0, 1)),
              ]),
              child: Image.network(
                "https://m.media-amazon.com/images/M/MV5BMTkzNjEzMDEzMF5BMl5BanBnXkFtZTgwMDI0MjE4MjE@._V1_.jpg",
                fit: BoxFit.cover,
              ),
            ),
            verticalSpaceMedium,
            Text("Peaky Blinders",
                style: TextStyle(
                  fontSize: 18.0,
                  color: Focus.of(context).hasPrimaryFocus
                      ? Colors.black
                      : Colors.white,
                )),
            const SizedBox(height: 5),
            Text(
              "2022",
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 5),
            Text(
              "Lorem ipsum",
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardSideBar extends StatelessWidget {
  const DashboardSideBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      child: Ink(
        decoration: BoxDecoration(color: Colors.grey[900]),
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: ListView(
            key: GlobalKey(debugLabel: "dashboardSideBar"),
            shrinkWrap: true,
            controller: ScrollController(),
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.list),
                title: Text(
                  'Home',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                selected: true,
                onTap: () {},
                selectedTileColor: Colors.grey[800],
                textColor: Colors.white,
                // selectedColor: Colors.white,
              ),
              ListTile(
                leading: Icon(Icons.list),
                title: Text('Favorites'),
                selected: false,
                onTap: () {},
                selectedTileColor: Colors.grey[800],
                textColor: Colors.white,
                selectedColor: Colors.white,
              ),
              ListTile(
                leading: Icon(Icons.list),
                title: Text('Watchlist'),
                selected: false,
                onTap: () {},
                selectedTileColor: Colors.grey[800],
                textColor: Colors.white,
                selectedColor: Colors.white,
              ),
              ListTile(
                leading: Icon(Icons.list),
                title: Text('Series'),
                selected: false,
                onTap: () {},
                selectedTileColor: Colors.grey[800],
                textColor: Colors.white,
                selectedColor: Colors.white,
              ),
              ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text('Logout'),
                selected: false,
                onTap: () {},
                selectedTileColor: Colors.grey[800],
                textColor: Colors.white,
                selectedColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
