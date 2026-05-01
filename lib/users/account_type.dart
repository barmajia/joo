enum AccountType { seller, factory, customer, middleman }

String asString(AccountType accountType) {
  switch (accountType) {
    case AccountType.seller:
      return 'seller';
    case AccountType.factory:
      return 'factory';
    case AccountType.customer:
      return 'customer';
    case AccountType.middleman:
      return 'middleman';
  }
}
