import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../utils/loading.dart';
import 'edit_agencies_screen.dart';
import 'upload_agency_screen.dart';

class TravelAgencyPage extends StatefulWidget {
  const TravelAgencyPage({super.key});

  @override
  TravelAgencyPageState createState() => TravelAgencyPageState();
}

class TravelAgencyPageState extends State<TravelAgencyPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> filteredAgencies = [];
  List<Map<String, dynamic>> allAgencies = [];
  String selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _fetchAgencies();
  }

  Future<void> _fetchAgencies() async {
    final firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore.collection('agencies').get();
      final agenciesList = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (mounted) {
        setState(() {
          allAgencies = agenciesList..shuffle(Random());
          filteredAgencies = allAgencies;
        });
      }
    } catch (e) {
      print("Error fetching agencies: $e");
    }
  }

  List<String> getCategories() {
    final categories = allAgencies.map((agency) => agency['category']).toSet();
    return ['All', ...categories];
  }

  void _filterAgencies(String query) {
    setState(() {
      filteredAgencies = allAgencies.where((agency) {
        final matchSearch =
            agency['agencyName'].toLowerCase().contains(query.toLowerCase());
        final matchCategory =
            selectedCategory == "All" || agency['category'] == selectedCategory;

        return matchSearch && matchCategory;
      }).toList();
    });
  }

  Future<void> _refreshData() async {
    await _fetchAgencies();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> categories = getCategories();

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                _filterAgencies(query);
              },
              decoration: InputDecoration(
                hintText: 'Search....',
                prefixIcon: const Icon(Icons.search),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterAgencies('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                final isSelected = category == selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                      _filterAgencies(_searchController.text);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Expanded(
            child: RefreshIndicator(
                onRefresh: _refreshData,
                child: ListView.builder(
                  padding: const EdgeInsets.all(
                      0.0), // No space between the list items
                  itemCount: filteredAgencies.length,
                  itemBuilder: (context, index) {
                    final agency = filteredAgencies[index];
                    return GestureDetector(
                      onTap: () {
                        final url = Uri.parse(agency['agencyWeb']!);
                        if (url.scheme == 'http' || url.scheme == 'https') {
                          launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          ).catchError((error) {
                            if (mounted) {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Could not open ${url.toString()}'),
                                ),
                              );
                            }
                            return true;
                          });
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Invalid URL: ${url.toString()}'),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color:
                              Colors.grey[100], // Light grey background color
                          // Removed border radius for no rounded corners
                        ),
                        child: Row(
                          children: [
                            ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: agency['agencyImage']!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const LoadingAnimation(),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                agency['agencyName']!,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditAgencyPage(agency: agency),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('agencies')
                                    .doc(agency['id'])
                                    .delete();
                                _refreshData(); // Refresh after deletion
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return const UploadAgencyPage();
            },
          );
        },
        backgroundColor: Colors.blue,
        mini: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
