import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(body: SlideShow()));
  }
}

class SlideShow extends StatefulWidget {
  createState() => _SlideShowState();
}

class _SlideShowState extends State<SlideShow> {
  final PageController _pageController = PageController(viewportFraction: 0.8);
  final Firestore firestore = Firestore.instance;

  Stream slides;
  String activeTag = 'favorites';

  int currentPage = 0;

  @override
  void initState() {
    super.initState();

    _dbQuery();

    _pageController.addListener(() {
      int next = _pageController.page.round();

      if (currentPage != next) {
        setState(() {
          currentPage = next;
        });
      }
    });
  }

  void _dbQuery({String tag = 'favorites'}) {
    slides = firestore
        .collection('stories')
        .where('tags', arrayContains: tag)
        .snapshots()
        .map((lists) => lists.documents.map((doc) => doc.data));

    setState(() {
      activeTag = tag;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: slides,
      initialData: [],
      builder: (context, AsyncSnapshot snap) {
        List slideList = snap.data.toList();

        return PageView.builder(
          controller: _pageController,
          itemCount: slideList.length + 1,
          itemBuilder: (context, int currentIndex) {
            if (currentIndex == 0) {
              return _buildTagPage();
            }

            if (slideList.length >= currentIndex) {
              bool active = currentIndex == currentPage;
              return _buildStoryPage(slideList[currentIndex - 1], active);
            }
          },
        );
      },
    );
  }

  Widget _buildStoryPage(slideList, bool active) {
    final double blur = active ? 40 : 0;
    final double offset = active ? 20 : 0;
    final double top = active ? 100 : 200;

    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOutExpo,
      margin: EdgeInsets.only(top: top, bottom: 100, right: 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          fit: BoxFit.cover,
          image: NetworkImage(slideList['img']),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            blurRadius: blur,
            offset: Offset(offset, offset),
          )
        ],
      ),
      child: Center(
        child: Text(
          slideList['title'],
          style: TextStyle(fontSize: 40, color: Colors.white),
        ),
      ),
    );
  }

  _buildTagPage() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Your stories',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildButton('favorites'),
          _buildButton('bridge'),
          _buildButton('erotic'),
        ],
      ),
    );
  }

  _buildButton(tag) {
    var buttonColor = tag == activeTag ? Colors.purple : Colors.white;
    var textColor = tag == activeTag ? Colors.white : Colors.purple;

    return FlatButton(
      color: buttonColor,
      child: Text(
        '#$tag',
        style: TextStyle(color: textColor),
      ),
      onPressed: () => _dbQuery(tag: tag),
    );
  }
}
