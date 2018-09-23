import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Collection',
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/collection':
            return new MyCustomRoute(
                builder: (_) => BookCollectionPage(), settings: settings);
          case '/browse':
            return new MyCustomRoute(
                builder: (_) => SearchBookPage(), settings: settings);
        }
      },
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new BookCollectionPage(),
    );
  }
}

class MyCustomRoute<T> extends MaterialPageRoute<T> {
  MyCustomRoute({WidgetBuilder builder, RouteSettings settings})
      : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (settings.isInitialRoute) return child;
    return new FadeTransition(opacity: animation, child: child);
  }
}

class BookCollectionPage extends StatefulWidget {
  @override
  State<BookCollectionPage> createState() {
    return new _BookCollectionState();
  }
}

class _BookCollectionState extends State<BookCollectionPage> {
  List<Book> books = List();

  @override
  Widget build(BuildContext context) {
    return new NavigationWidget(
        title: 'My Collection', body: new Text('My Collection Page'));
  }
}

class SearchBookPage extends StatefulWidget {
  @override
  State<SearchBookPage> createState() {
    return new _SearchBookState();
  }
}

class _SearchBookState extends State<SearchBookPage> {
  String searchTerm = '';

  refresh(String text) {
    setState(() {
      searchTerm = text.replaceAll(" ", "+");
    });
  }

  @override
  Widget build(BuildContext context) {
    return new NavigationWidget(
      body: _getBody(),
      title: 'Browse Books',
      appBar: buildSearchAppBar(refresh),
    );
  }

  Widget _getBody() {
    return FutureBuilder<List<Book>>(
        future: fetchBook(searchTerm),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return GridView.count(
                crossAxisCount: 1,
                children: List.generate(snapshot.data.length, (index) {
                  Book book = snapshot.data[index];
                  return Card(
                      child: Column(children: [
                    Row(children: [
                      Expanded(child: Text(book.title)),
                      Image.network(book.thumbnail),
                    ]),
                    Text(
                      book.description,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 8,
                    )
                  ]));
                }));
          } else if (snapshot.hasError) {
            return Center(child: Text('Search for Books!'));
          }
          return Center(child: CircularProgressIndicator());
        });
  }
}

PreferredSize buildSearchAppBar(Function(String term) notifyParent) {
  return PreferredSize(
      preferredSize: Size.fromHeight(56.0),
      child: Builder(
          builder: (context) => Container(
              decoration:
                  new BoxDecoration(color: Colors.deepPurple, boxShadow: [
                new BoxShadow(
                  color: Colors.black,
                  blurRadius: 4.0,
                ),
              ]),
              child: Padding(
                  padding: EdgeInsets.fromLTRB(10.0, 30.0, 10.0, 10.0),
                  child: Card(
                      margin: EdgeInsets.all(0.0),
                      child: _buildSearchAppBarChild(context, notifyParent))))));
}

Widget _buildSearchAppBarChild(BuildContext context, Function(String term) notifyParent) {
  var textController = TextEditingController();

  return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    IconButton(
        icon: Icon(Icons.menu),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        }),
    Expanded(
        child: TextField(
      controller: textController,
      decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Browse Books',
          hintStyle: TextStyle(fontSize: 20.0, color: Colors.grey)),
    )),
    IconButton(
        icon: Icon(Icons.search),
        onPressed: () {
          notifyParent(textController.text);
        })
  ]);
}

Future<List<Book>> fetchBook(String searchTerm) async {
  final response = await http
      .get('https://www.googleapis.com/books/v1/volumes?q=' + searchTerm);
  if (response.statusCode == 200) {
    // If server returns an OK response, parse the JSON
    return compute(parseBooks, response.body);
  } else {
    // If that response was not OK, throw an error.
    throw Exception('Failed to load post');
  }
}

List<Book> parseBooks(String responseBody) {
  final parsed = json.decode(responseBody);
  return parsed['items']
      .map<Book>((json) => Book.fromJson(json['volumeInfo']))
      .toList();
}

class Book {
  final String title;
  final List<String> authors;
  final int pageCount;
  final String description;
  final String thumbnail;

  Book(
      {this.title,
      this.authors,
      this.pageCount,
      this.description,
      this.thumbnail});

  factory Book.fromJson(Map<String, dynamic> json) {
    List<dynamic> authors = json['authors'] ?? new List<dynamic>();
    return Book(
        title: json['title'],
        authors: new List<String>.from(authors),
        pageCount: json['pageCount'],
        description: json['description'] != null ? json['description'] : '',
        thumbnail:
            json['imageLinks'] != null ? json['imageLinks']['thumbnail'] : '');
  }
}

class NavigationWidget extends StatefulWidget {
  final Widget body;
  final PreferredSizeWidget appBar;
  final String title;

  NavigationWidget({@required this.title, @required this.body, this.appBar})
      : assert(title != null && title.isNotEmpty),
        assert(body != null);

  @override
  State<NavigationWidget> createState() {
    return NavigationState();
  }
}

class NavigationState extends State<NavigationWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: widget.appBar != null
            ? widget.appBar
            : buildDefaultAppBar(widget.title),
        drawer: _buildDrawer(context),
        body: widget.body);
  }

  AppBar buildDefaultAppBar(String title) {
    return new AppBar(
      backgroundColor: Colors.deepPurple,
      title: Text(title),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return new Drawer(
        child: new ListView(
      children: <Widget>[
        DrawerHeader(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(child: Text('Written By Blopditu')),
              Expanded(child: Icon(Icons.code)),
              Expanded(child: Text('aka Sujathan Kamalaranjithan'))
            ],
          ),
          decoration: BoxDecoration(
            color: Colors.white30,
          ),
        ),
        InkWell(
            child: new ListTile(
          leading: Icon(Icons.book),
          title: Text('My Collection'),
          subtitle: Text('View your collection'),
          onTap: () {
            Navigator.popAndPushNamed(context, '/collection');
          },
        )),
        new ListTile(
          leading: Icon(Icons.search),
          title: Text('Browse Books'),
          subtitle: Text('Find your next book!'),
          onTap: () {
            Navigator.popAndPushNamed(context, '/browse');
          },
        ),
      ],
    ));
  }
}
