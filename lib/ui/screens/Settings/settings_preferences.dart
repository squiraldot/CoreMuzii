bool resolveBottomNavBarPreference({
  required bool isDesktop,
  required dynamic storedValue,
}) {
  if (isDesktop) return false;
  return storedValue is bool ? storedValue : true;
}
