import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewScreen extends StatefulWidget {
  final String garageId;

  ReviewScreen({required this.garageId});

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  double rating = 3;
  TextEditingController reviewController = TextEditingController();

  Future submitReview() async {
    await FirebaseFirestore.instance.collection("reviews").add({
      "garageId": widget.garageId,
      "rating": rating,
      "review": reviewController.text,
      "date": DateTime.now(),
    });

    reviewController.clear();

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Review Submitted")));
  }

  Widget buildStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.yellow,
          ),
          onPressed: () {
            setState(() {
              rating = index + 1;
            });
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title:
        Text("Garage Reviews", style: TextStyle(color: Colors.greenAccent)),
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          buildStars(),

          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              controller: reviewController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Write Review",
                labelStyle: TextStyle(color: Colors.green),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
            ),
          ),

          ElevatedButton(
            onPressed: submitReview,
            child: Text("Submit"),
          ),

          Divider(color: Colors.white),

          /// 🔥 SHOW REVIEWS LIST
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("reviews")
                  .where("garageId", isEqualTo: widget.garageId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();

                var reviews = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    var data = reviews[index];

                    return ListTile(
                      title: Text(data["review"],
                          style: TextStyle(color: Colors.white)),
                      subtitle: Row(
                        children: List.generate(
                          data["rating"].toInt(),
                              (i) => Icon(Icons.star, color: Colors.yellow, size: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}