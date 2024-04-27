import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rnt_spots/dtos/property_dto.dart';
import 'package:rnt_spots/widgets/property_listing/property_details.dart';

class ReservationScreen extends StatelessWidget {
  final String? reserveBy;
  final String? reserveTo;

  ReservationScreen({Key? key, this.reserveBy, this.reserveTo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservations'),
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
          reservationQuery.where('reservedBy', isEqualTo: reserveBy);
    }

    if (reserveTo != null) {
      reservationQuery =
          reservationQuery.where('reservedTo', isEqualTo: reserveTo);
    }

    // Add orderBy clause to sort by bookedDate in descending order
    reservationQuery = reservationQuery.orderBy('bookedDate', descending: true);
    return StreamBuilder<QuerySnapshot>(
      stream: reservationQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No reservations found'),
          );
        }
        return ListView(
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            final data = document.data() as Map<String, dynamic>;
            final propertyId = data['propertyId'];
            final startDate = data['startDate'];
            final endDate = data['endDate'];
            final reserveBy = data['reservedByName'];
            final bookedDate = data['bookedDate'];
            final paymentMethod = data['paymentMethod'];
            final status = data['status'];
            final receiptUrl = data['receiptUrl'];
            final read = data['read'];
            // Format the timestamp
            final formattedStartDate =
                DateFormat('MMM dd, yyyy').format(startDate.toDate());
            // Format the timestamp
            final formattedEndDate =
                DateFormat('MMM dd, yyyy').format(endDate.toDate());

            // Format the bookedDate
            final formattedBookedDate =
                DateFormat('MMMM dd, yyyy h:mm a').format(bookedDate.toDate());

            // Calculate the difference between bookedDate and current date
            final difference = bookedDate.toDate().difference(DateTime.now());
            final daysDifference = difference.inDays;

            // Check if the difference is less than 7 days
            final canCancel = daysDifference < 7;

            Future<void> _updateReservationReadStatus(
                DocumentReference reservationRef) async {
              try {
                await reservationRef.update({'read': true});
              } catch (error) {
                print('Error updating reservation read status: $error');
              }
            }

            void _updateReservationStatus(
                String newStatus, String propertyId) async {
              final QuerySnapshot querySnapshot = await FirebaseFirestore
                  .instance
                  .collection('Reservations')
                  .where('propertyId', isEqualTo: propertyId)
                  .get();

              if (querySnapshot.docs.isNotEmpty) {
                final reservationDocId = querySnapshot.docs.first.id;
                FirebaseFirestore.instance
                    .collection('Reservations')
                    .doc(reservationDocId)
                    .update({'status': newStatus}).then((value) async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reservation status updated to $newStatus'),
                    ),
                  ); // If the new status is "Accepted", update property status to "Reserved"
                  if (newStatus == 'Accepted') {
                    await FirebaseFirestore.instance
                        .collection('Properties')
                        .doc(propertyId)
                        .update({'Status': 'Reserved'}).then((value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Property status updated to Reserved'),
                        ),
                      );
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Failed to update property status: $error'),
                        ),
                      );
                    });
                  } else {
                    await FirebaseFirestore.instance
                        .collection('Properties')
                        .doc(propertyId)
                        .update({'Status': 'Available'}).then((value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Property status updated to Reserved'),
                        ),
                      );
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Failed to update property status: $error'),
                        ),
                      );
                    });
                  }
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Failed to update reservation status: $error'),
                    ),
                  );
                });
              }
            }

            return Container(
              decoration: BoxDecoration(
                color: read
                    ? Colors.white
                    : Color.fromARGB(146, 248, 96,
                        96), // Choose your desired background color
                borderRadius: BorderRadius.circular(
                    10), // Optional: Add border radius for rounded corners
              ),
              child: ListTile(
                  title: Text('Property ID: $propertyId'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reserve By: $reserveBy'),
                      Text('Reserve Date: $formattedBookedDate'),
                      Text('Start Date: $formattedStartDate'),
                      Text('End Date: $formattedEndDate'),
                      Text('Payment Method: $paymentMethod'),
                      Text('Status: $status'),
                    ],
                  ),
                  trailing: reserveTo != null && status == 'Pending'
                      ? ElevatedButton(
                          onPressed: () async {
                            await _updateReservationReadStatus(
                                document.reference);
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Reservation Confirmation'),
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (receiptUrl != null &&
                                        receiptUrl.isNotEmpty)
                                      Center(
                                        child: Image.network(
                                          receiptUrl,
                                          width: 200,
                                          height: 200,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Text('Property ID: $propertyId'),
                                    Text('Reserve By: $reserveBy'),
                                    Text('Reserve Date: $formattedBookedDate'),
                                    Text('Start Date: $formattedStartDate'),
                                    Text('End Date: $formattedEndDate'),
                                    Text('Payment Method: $paymentMethod'),
                                    Text('Status: $status'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _updateReservationStatus(
                                          'Accepted', propertyId);
                                    },
                                    child: const Text('Accept'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _updateReservationStatus(
                                          'Rejected', propertyId);
                                    },
                                    child: const Text('Reject'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('Properties')
                                          .doc(propertyId)
                                          .get()
                                          .then((propertySnapshot) {
                                        if (propertySnapshot.exists) {
                                          final propertyData = propertySnapshot
                                              .data() as Map<String, dynamic>;
                                          final property =
                                              PropertyDto.fromFirestore(
                                                  propertyData, propertyId);

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PropertyDetails(
                                                      property: property),
                                            ),
                                          );
                                        }
                                      });
                                    },
                                    child: const Text('View Property'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Accept/Reject'),
                        )
                      : ElevatedButton(
                          onPressed: () async {
                            if (reserveTo != null) {
                              await _updateReservationReadStatus(
                                  document.reference);
                            }
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Reservation Confirmation'),
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (receiptUrl != null &&
                                        receiptUrl.isNotEmpty)
                                      Center(
                                        child: Image.network(
                                          receiptUrl,
                                          width: 200,
                                          height: 200,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Text('Property ID: $propertyId'),
                                    Text('Reserve By: $reserveBy'),
                                    Text('Reserve Date: $formattedBookedDate'),
                                    Text('Start Date: $formattedStartDate'),
                                    Text('End Date: $formattedEndDate'),
                                    Text('Payment Method: $paymentMethod'),
                                    Text('Status: $status'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('Properties')
                                          .doc(propertyId)
                                          .get()
                                          .then((propertySnapshot) {
                                        if (propertySnapshot.exists) {
                                          final propertyData = propertySnapshot
                                              .data() as Map<String, dynamic>;
                                          final property =
                                              PropertyDto.fromFirestore(
                                                  propertyData, propertyId);

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PropertyDetails(
                                                      property: property),
                                            ),
                                          );
                                        }
                                      });
                                    },
                                    child: const Text('View Property'),
                                  ),
                                  if (canCancel && status != "Cancelled")
                                    TextButton(
                                      onPressed: () {
                                        _updateReservationStatus(
                                            "Cancelled", propertyId);
                                      },
                                      child: const Text('Cancel Reservation'),
                                    ),
                                ],
                              ),
                            );
                          },
                          child: const Text('View'),
                        )),
            );
          }).toList(),
        );
      },
    );
  }
}
