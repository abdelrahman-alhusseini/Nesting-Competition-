enum BookingType {
  normal,
  crossSell,
  remodelingCrossSell,
  dueInspection,
  restoration,
}

extension BookingTypeX on BookingType {
  String get label {
    switch (this) {
      case BookingType.normal:
        return 'Normal Booking';
      case BookingType.crossSell:
        return 'Cross-Sell Booking';
      case BookingType.remodelingCrossSell:
        return 'Remodeling Cross-Sell';
      case BookingType.dueInspection:
        return 'Due Inspection';
      case BookingType.restoration:
        return 'Restoration';
    }
  }

  String get databaseValue {
    switch (this) {
      case BookingType.normal:
        return 'normal';
      case BookingType.crossSell:
        return 'cross_sell';
      case BookingType.remodelingCrossSell:
        return 'remodeling_cross_sell';
      case BookingType.dueInspection:
        return 'due_inspection';
      case BookingType.restoration:
        return 'restoration';
    }
  }

  double get specialChance {
    switch (this) {
      case BookingType.normal:
        return 0.05;
      case BookingType.crossSell:
        return 0.50;
      case BookingType.remodelingCrossSell:
        return 1.00;
      case BookingType.dueInspection:
        return 0.25;
      case BookingType.restoration:
        return 0.15;
    }
  }

  static BookingType fromDatabase(String value) {
    switch (value) {
      case 'cross_sell':
        return BookingType.crossSell;
      case 'remodeling_cross_sell':
        return BookingType.remodelingCrossSell;
      case 'due_inspection':
        return BookingType.dueInspection;
      case 'restoration':
        return BookingType.restoration;
      case 'normal':
      default:
        return BookingType.normal;
    }
  }
}
