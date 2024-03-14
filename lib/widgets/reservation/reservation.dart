import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReservationScreen extends StatelessWidget {
  final String? reserveBy;
  final String? reserveTo;

  ReservationScreen({Key? key, this.reserveBy, this.reserveTo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reservations'),
      ),
      body: ReservationList(
        reserveBy: reserveBy,
        reserveTo: reserveTo,
      ),
    );
  }
}

class ReservationList extends StatelessWidget {
  final String? reserveBy;
  final String? reserveTo;

  ReservationList({this.reserveBy, this.reserveTo});

  @override
  Widget build(BuildContext context) {
    Query reservationQuery =
        FirebaseFirestore.instance.collection('Reservations');

    if (reserveBy != null) {
      reservationQuery =
          reservationQuery.where('reserveBy', isEqualTo: reserveBy);
    }

    if (reserveTo != null) {
      reservationQuery =
          reservationQuery.where('reserveTo', isEqualTo: reserveTo);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: reservationQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No reservations found'),
          );
        }
        return ListView(
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            final data = document.data() as Map<String, dynamic>;
            final propertyId = data['propertyId'];
            final reservationDate = data['reservationDate'];
            final paymentMethod = data['paymentMethod'];
            final status = data['status'];
            // Format the timestamp
            final formattedDate =
                DateFormat('MMM dd, yyyy').format(reservationDate.toDate());

             void _updateReservationStatus(String newStatus, String propertyId) async {
              final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
                  .collection('Reservations')
                  .where('propertyId', isEqualTo: propertyId)
                  .get();

              if (querySnapshot.docs.isNotEmpty) {
                final reservationDocId = querySnapshot.docs.first.id;
                FirebaseFirestore.instance
                    .collection('Reservations')
                    .doc(reservationDocId)
                    .update({'status': newStatus})
                    .then((value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reservation status updated to $newStatus'),
                    ),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update reservation status: $error'),
                    ),
                  );
                });
              }
            }

            return ListTile(
              title: Text('Property ID: $propertyId'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reservation Date: $formattedDate'),
                  Text('Payment Method: $paymentMethod'),
                  Text('Status: $status'),
                ],
              ),
              trailing: status == 'Pending' ? ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Reservation Confirmation'),
                      content: Text('Accept or reject this reservation?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _updateReservationStatus('Accepted', propertyId);
                          },
                          child: Text('Accept'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _updateReservationStatus('Rejected', propertyId);
                          },
                          child: Text('Reject'),
                        ),
                      ],
                    ),
                  );
                },
                child: Text('Accept/Reject'),
              ) : null,
            );
          }).toList(),
        );
      },
    );
  }
}
