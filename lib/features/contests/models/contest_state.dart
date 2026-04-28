import 'package:flutter/material.dart';

class ContestItem {
  final String id;
  final String title;
  final String platform;
  final String level;
  final String date;
  final String url;
  final Color iconColor;
  final bool isCourse; // To distinguish between contests and courses

  ContestItem({
    required this.id,
    required this.title,
    required this.platform,
    required this.level,
    required this.date,
    required this.url,
    required this.iconColor,
    this.isCourse = false,
  });
}

final ValueNotifier<List<ContestItem>> contestState = ValueNotifier([
  ContestItem(id: 'c1', iconColor: Colors.blue, title: 'Codeforces Rounds', platform: 'Codeforces', level: 'Div 1, 2, 3, 4', date: 'Frequent / Weekly', url: 'https://codeforces.com/contests'),
  ContestItem(id: 'c2', iconColor: Colors.orange, title: 'LeetCode Weekly Contest', platform: 'LeetCode', level: 'All Levels', date: 'Every Sunday', url: 'https://leetcode.com/contest/'),
  ContestItem(id: 'c3', iconColor: Colors.teal, title: 'AtCoder Beginner Contest', platform: 'AtCoder', level: 'Beginner / Intermediate', date: 'Weekends', url: 'https://atcoder.jp/contests/'),
  ContestItem(id: 'c4', iconColor: Colors.brown, title: 'CodeChef Starters', platform: 'CodeChef', level: 'Rated for All', date: 'Every Wednesday', url: 'https://www.codechef.com/contests'),
  ContestItem(id: 'c5', iconColor: Colors.indigo, title: 'HackerEarth Challenges', platform: 'HackerEarth', level: 'Various', date: 'Ongoing & Monthly', url: 'https://www.hackerearth.com/challenges/'),
]);

final ValueNotifier<List<ContestItem>> courseState = ValueNotifier([
  ContestItem(id: 'co1', iconColor: Colors.redAccent, title: "CS50's Intro to Computer Science", platform: 'Harvard University', level: 'Free / Cert Optional', date: '', url: 'https://pll.harvard.edu/course/cs50-introduction-computer-science', isCourse: true),
  ContestItem(id: 'co2', iconColor: Colors.indigo, title: 'Responsive Web Design', platform: 'freeCodeCamp', level: 'Free Certificate', date: '', url: 'https://www.freecodecamp.org/learn/responsive-web-design/', isCourse: true),
  ContestItem(id: 'co3', iconColor: Colors.blue, title: 'Machine Learning Specialization', platform: 'DeepLearning.AI', level: 'Free to Audit', date: '', url: 'https://www.coursera.org/specializations/machine-learning-introduction', isCourse: true),
  ContestItem(id: 'co4', iconColor: Colors.teal, title: 'Full Stack Open', platform: 'University of Helsinki', level: 'Free Certificate', date: '', url: 'https://fullstackopen.com/en/', isCourse: true),
  ContestItem(id: 'co5', iconColor: Colors.amber, title: 'Elements of AI', platform: 'University of Helsinki', level: 'Free Certificate', date: '', url: 'https://www.elementsofai.com/', isCourse: true),
]);
