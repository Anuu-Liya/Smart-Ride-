import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/booking.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class BookingFuelScreen extends StatefulWidget {
  const BookingFuelScreen({super.key});

  @override
  State<BookingFuelScreen> createState() => _BookingFuelScreenState();
}

class _BookingFuelScreenState extends State<BookingFuelScreen> {
  final _service = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  final _customerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleNameController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _notesController = TextEditingController();

  final List<String> _serviceTypes = const [
    'Full Service',
    'Oil Change',
    'Engine Diagnostics',
    'Battery Check',
    'Brake Inspection',
    'AC Service',
  ];

  final List<String> _vehicleTypes = const [
    'Sedan',
    'SUV',
    'Hatchback',
    'Van',
    'Pickup',
    'Motorbike',
  ];

  final List<String> _packages = const ['Basic', 'Standard', 'Premium'];
  final List<int> _reminderOptions = const [2, 6, 12, 24, 48];
  final List<String> _garages = const [
    'AutoCare Premium Center',
    'QuickFix Service Hub',
    'Urban Motors Garage',
    'Elite Car Clinic',
  ];

  String _selectedService = 'Full Service';
  String _selectedVehicleType = 'Sedan';
  String _selectedPackage = 'Standard';
  String _selectedGarage = 'AutoCare Premium Center';
  int _selectedReminderHours = 24;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 30);
  bool _isSaving = false;

  @override
  void dispose() {
    _customerNameController.dispose();
    _phoneController.dispose();
    _vehicleNameController.dispose();
    _vehicleNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime get _appointmentDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  double get _estimatedPrice {
    const serviceBase = {
      'Full Service': 18000.0,
      'Oil Change': 8500.0,
      'Engine Diagnostics': 12000.0,
      'Battery Check': 5000.0,
      'Brake Inspection': 9500.0,
      'AC Service': 11000.0,
    };

    const packageMultiplier = {
      'Basic': 1.0,
      'Standard': 1.2,
      'Premium': 1.45,
    };

    return (serviceBase[_selectedService] ?? 10000) *
        (packageMultiplier[_selectedPackage] ?? 1.0);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) return;
    final appointment = _appointmentDateTime;
    if (appointment.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a future appointment time.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final booking = Booking(
      id: id,
      customerName: _customerNameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      vehicleName: _vehicleNameController.text.trim(),
      vehicleNumber: _vehicleNumberController.text.trim().toUpperCase(),
      vehicleType: _selectedVehicleType,
      serviceType: _selectedService,
      packageType: _selectedPackage,
      garageName: _selectedGarage,
      notes: _notesController.text.trim(),
      status: 'Upcoming',
      estimatedPrice: _estimatedPrice,
      reminderHours: _selectedReminderHours,
      appointmentDateTime: appointment,
      createdAt: DateTime.now(),
    );

    try {
      await _service.saveBooking(booking);
      await NotificationService().scheduleServiceReminder(
        bookingId: booking.id,
        title: 'Service reminder',
        body:
            '${booking.serviceType} for ${booking.vehicleName} is due in ${booking.reminderHours} hour(s).',
        appointmentDateTime: booking.appointmentDateTime,
        reminderHoursBefore: booking.reminderHours,
      );
      await NotificationService().showInstantReminder(
        title: 'Booking confirmed',
        body:
            '${booking.serviceType} booked on ${DateFormat('dd MMM yyyy, hh:mm a').format(booking.appointmentDateTime)}.',
      );

      _formKey.currentState!.reset();
      _customerNameController.clear();
      _phoneController.clear();
      _vehicleNameController.clear();
      _vehicleNumberController.clear();
      _notesController.clear();
      setState(() {
        _selectedService = 'Full Service';
        _selectedVehicleType = 'Sedan';
        _selectedPackage = 'Standard';
        _selectedGarage = 'AutoCare Premium Center';
        _selectedReminderHours = 24;
        _selectedDate = DateTime.now().add(const Duration(days: 1));
        _selectedTime = const TimeOfDay(hour: 9, minute: 30);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service appointment created successfully.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateStatus(Booking booking, String status) async {
    await _service.updateBookingStatus(booking.id, status);
    if (status == 'Cancelled') {
      await NotificationService().cancelBookingReminders(booking.id);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Booking marked as $status.')),
    );
  }

  Future<void> _rescheduleBooking(Booking booking) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: booking.appointmentDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(booking.appointmentDateTime),
    );
    if (pickedTime == null) return;

    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    await _service.rescheduleBooking(
      booking.id,
      newDateTime,
      booking.reminderHours,
    );
    await NotificationService().scheduleServiceReminder(
      bookingId: booking.id,
      title: 'Service reminder',
      body:
          '${booking.serviceType} for ${booking.vehicleName} is due in ${booking.reminderHours} hour(s).',
      appointmentDateTime: newDateTime,
      reminderHoursBefore: booking.reminderHours,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking rescheduled successfully.')),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      case 'Rescheduled':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentText = DateFormat('EEE, dd MMM yyyy • hh:mm a')
        .format(_appointmentDateTime);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders & Booking System')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3E8FF), Color(0xFFF9FAFB)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _BookingHeroCard(
              appointmentText: appointmentText,
              estimatedPrice: _estimatedPrice,
              selectedPackage: _selectedPackage,
              selectedService: _selectedService,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create a premium service appointment',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Book faster, set auto reminders, and manage bookings from one place.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 18),
                      _sectionLabel('Customer details'),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _customerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Customer name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Enter the customer name'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().length < 10)
                                ? 'Enter a valid phone number'
                                : null,
                      ),
                      const SizedBox(height: 18),
                      _sectionLabel('Vehicle details'),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _vehicleNameController,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle name / model',
                          prefixIcon: Icon(Icons.directions_car_outlined),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Enter the vehicle name'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _vehicleNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle number',
                          prefixIcon: Icon(Icons.pin_outlined),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Enter the vehicle number'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedVehicleType,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle type',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: _vehicleTypes
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedVehicleType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 18),
                      _sectionLabel('Service preferences'),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedService,
                        decoration: const InputDecoration(
                          labelText: 'Service type',
                          prefixIcon: Icon(Icons.build_circle_outlined),
                        ),
                        items: _serviceTypes
                            .map((service) => DropdownMenuItem(
                                  value: service,
                                  child: Text(service),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedService = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGarage,
                        decoration: const InputDecoration(
                          labelText: 'Preferred garage',
                          prefixIcon: Icon(Icons.garage_outlined),
                        ),
                        items: _garages
                            .map((garage) => DropdownMenuItem(
                                  value: garage,
                                  child: Text(garage),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedGarage = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _sectionLabel('Package level'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _packages.map((pkg) {
                          final selected = pkg == _selectedPackage;
                          return ChoiceChip(
                            selected: selected,
                            label: Text(pkg),
                            onSelected: (_) =>
                                setState(() => _selectedPackage = pkg),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      _sectionLabel('Schedule & reminders'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoActionCard(
                              title: 'Date',
                              value: DateFormat('dd MMM yyyy').format(_selectedDate),
                              icon: Icons.calendar_month,
                              onTap: _pickDate,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InfoActionCard(
                              title: 'Time',
                              value: _selectedTime.format(context),
                              icon: Icons.access_time,
                              onTap: _pickTime,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Reminder lead time',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _reminderOptions.map((hours) {
                          final selected = hours == _selectedReminderHours;
                          return ChoiceChip(
                            selected: selected,
                            label: Text('$hours h before'),
                            onSelected: (_) =>
                                setState(() => _selectedReminderHours = hours),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Special notes',
                          hintText: 'Pickup request, brake noise, engine light, etc.',
                          prefixIcon: Icon(Icons.note_alt_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFF7C3AED),
                              child: Icon(Icons.auto_awesome, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Smart reminder flow enabled',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    'A local notification will be triggered $_selectedReminderHours hour(s) before the appointment.',
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _createBooking,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.book_online),
                          label: Text(_isSaving ? 'Saving...' : 'Confirm Appointment'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Live booking management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Monitor upcoming services, reschedule quickly, and keep customers informed.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            StreamBuilder(
              stream: _service.getBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.event_busy, size: 48, color: Colors.black38),
                          SizedBox(height: 12),
                          Text(
                            'No bookings yet',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Create your first appointment to activate smart reminders and booking management.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final bookings = snapshot.data!.docs
                    .map((doc) => Booking.fromMap(doc.data()))
                    .toList();

                final upcomingCount = bookings
                    .where((booking) => booking.status == 'Upcoming' || booking.status == 'Rescheduled')
                    .length;
                final completedCount =
                    bookings.where((booking) => booking.status == 'Completed').length;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStatCard(
                            label: 'Upcoming',
                            value: '$upcomingCount',
                            icon: Icons.upcoming,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniStatCard(
                            label: 'Completed',
                            value: '$completedCount',
                            icon: Icons.verified,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...bookings.map((booking) {
                      final statusColor = _statusColor(booking.status);
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3E8FF),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.build_circle_outlined,
                                        color: Color(0xFF7C3AED)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          booking.serviceType,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${booking.vehicleName} • ${booking.vehicleNumber}',
                                          style: const TextStyle(color: Colors.black54),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _tag(booking.packageType, const Color(0xFFF3E8FF), const Color(0xFF6D28D9)),
                                            _tag(booking.garageName, const Color(0xFFE0F2FE), const Color(0xFF0369A1)),
                                            _tag(booking.status, statusColor.withOpacity(.15), statusColor),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _detailRow(Icons.person_outline, booking.customerName),
                              _detailRow(Icons.phone_outlined, booking.customerPhone),
                              _detailRow(
                                Icons.schedule,
                                DateFormat('EEE, dd MMM yyyy • hh:mm a')
                                    .format(booking.appointmentDateTime),
                              ),
                              _detailRow(
                                Icons.notifications_active_outlined,
                                'Reminder set ${booking.reminderHours} hour(s) before',
                              ),
                              _detailRow(
                                Icons.payments_outlined,
                                'Estimated LKR ${booking.estimatedPrice.toStringAsFixed(0)}',
                              ),
                              if (booking.notes.isNotEmpty)
                                _detailRow(Icons.sticky_note_2_outlined, booking.notes),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _rescheduleBooking(booking),
                                    icon: const Icon(Icons.edit_calendar),
                                    label: const Text('Reschedule'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => NotificationService().showInstantReminder(
                                      title: 'Manual reminder',
                                      body:
                                          '${booking.serviceType} for ${booking.vehicleName} is booked for ${DateFormat('dd MMM, hh:mm a').format(booking.appointmentDateTime)}.',
                                    ),
                                    icon: const Icon(Icons.notifications),
                                    label: const Text('Send Reminder'),
                                  ),
                                  FilledButton.tonalIcon(
                                    onPressed: booking.status == 'Completed'
                                        ? null
                                        : () => _updateStatus(booking, 'Completed'),
                                    icon: const Icon(Icons.check_circle_outline),
                                    label: const Text('Complete'),
                                  ),
                                  FilledButton.tonalIcon(
                                    onPressed: booking.status == 'Cancelled'
                                        ? null
                                        : () => _updateStatus(booking, 'Cancelled'),
                                    icon: const Icon(Icons.cancel_outlined),
                                    label: const Text('Cancel'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      );

  Widget _tag(String text, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _BookingHeroCard extends StatelessWidget {
  final String appointmentText;
  final double estimatedPrice;
  final String selectedPackage;
  final String selectedService;

  const _BookingHeroCard({
    required this.appointmentText,
    required this.estimatedPrice,
    required this.selectedPackage,
    required this.selectedService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF6D28D9), Color(0xFF9333EA), Color(0xFFC084FC)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x336D28D9), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.notifications_active, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Smart Reminders & Booking Hub',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            selectedService,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            appointmentText,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _heroStat('Package', selectedPackage),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _heroStat('Est. cost', 'LKR ${estimatedPrice.toStringAsFixed(0)}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _InfoActionCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _InfoActionCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF7C3AED)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFF3E8FF),
            child: Icon(icon, color: const Color(0xFF7C3AED)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black54)),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
