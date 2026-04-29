enum AccountType { seller, factory, customser, middleman }

String asString(AccountType accountType) {
  switch (accountType) {
    case AccountType.seller:
      return 'seller';
    case AccountType.factory:
      return 'factory';
    case AccountType.customser:
      return 'customser';
    case AccountType.middleman:
      return 'middleman';
  }
}
