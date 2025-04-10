import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Sample user data - in a real app, this would come from a database or API
  String username = "HistoryExplorer";
  String email = "explorer@example.com";
  String bio = "History enthusiast exploring historical markers across the United States.";
  int markersVisited = 24;
  List<String> favoriteMarkers = [
    "Chickamauga Battlefield",
    "Lookout Mountain",
    "Battle of Nashville"
  ];

  // Theme preferences
  String selectedTheme = "Default";

  // Notification preferences
  bool enableNotifications = true;
  double searchRadius = 20.0; // in km

  // Controllers for text editing
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: username);
    _emailController = TextEditingController(text: email);
    _bioController = TextEditingController(text: bio);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Show dialog to edit profile information
  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                username = _usernameController.text;
                email = _emailController.text;
                bio = _bioController.text;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Show dialog to edit search radius
  void _showRadiusSettingDialog() {
    TextEditingController radiusController = TextEditingController(text: searchRadius.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Radius'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set the radius (in km) for finding nearby markers:'),
            const SizedBox(height: 16),
            TextField(
              controller: radiusController,
              decoration: const InputDecoration(
                labelText: 'Radius (km)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            Slider(
              value: searchRadius,
              min: 5,
              max: 50,
              divisions: 9,
              label: searchRadius.round().toString(),
              onChanged: (value) {
                setState(() {
                  searchRadius = value;
                  radiusController.text = value.toString();
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                searchRadius = double.tryParse(radiusController.text) ?? 20.0;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Show dialog to add a new favorite marker
  void _showAddFavoriteDialog() {
    final TextEditingController markerNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Favorite Marker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the name of the historical marker:'),
            const SizedBox(height: 16),
            TextField(
              controller: markerNameController,
              decoration: const InputDecoration(
                labelText: 'Marker Name',
                border: OutlineInputBorder(),
                hintText: 'e.g. Gettysburg Address',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final String markerName = markerNameController.text.trim();
              if (markerName.isNotEmpty) {
                setState(() {
                  favoriteMarkers.add(markerName);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$markerName added to favorites')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a marker name')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditProfileDialog,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header with avatar and name
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.amber,
                        child: Icon(Icons.person, size: 50, color: Colors.white),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Change profile picture feature coming soon')),
                              );
                            },
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      bio,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Stats section
            const Text(
              "Your Stats",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("Markers Visited", markersVisited.toString()),
                    _buildStatItem("Favorites", favoriteMarkers.length.toString()),
                    _buildStatItem("States", "3"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Favorite markers section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Favorite Markers",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: _showAddFavoriteDialog,
                  tooltip: 'Add favorite marker',
                ),
              ],
            ),
            const SizedBox(height: 8),
            favoriteMarkers.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "No favorite markers yet. Add some by clicking the + button above.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: favoriteMarkers.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: Dismissible(
                          key: Key(favoriteMarkers[index]),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16.0),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            setState(() {
                              String removed = favoriteMarkers.removeAt(index);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("$removed removed from favorites"),
                                  action: SnackBarAction(
                                    label: 'UNDO',
                                    onPressed: () {
                                      setState(() {
                                        favoriteMarkers.insert(index, removed);
                                      });
                                    },
                                  ),
                                ),
                              );
                            });
                          },
                          child: ListTile(
                            leading: const Icon(Icons.pin_drop, color: Colors.amber),
                            title: Text(favoriteMarkers[index]),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.map, size: 20),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Navigating to ${favoriteMarkers[index]}"))
                                    );
                                  },
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                            onTap: () {
                              // Navigate to marker details
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Viewing ${favoriteMarkers[index]}"))
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 24),

            // Settings section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Settings",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Save Settings"),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Settings saved successfully")),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text("Notifications"),
                    subtitle: const Text("Receive alerts about nearby markers"),
                    trailing: Switch(
                      value: enableNotifications,
                      onChanged: (value) {
                        setState(() {
                          enableNotifications = value;
                        });
                      },
                      activeColor: Colors.amber,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.radar),
                    title: const Text("Search Radius"),
                    subtitle: Text("${searchRadius.toStringAsFixed(1)} km"),
                    trailing: const Icon(Icons.edit),
                    onTap: _showRadiusSettingDialog,
                  ),
                  const Divider(height: 1),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
                      final isSystemMode = themeProvider.themeMode == ThemeMode.system;

                      return Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.dark_mode),
                            title: const Text("Dark Mode"),
                            subtitle: Text(isSystemMode
                              ? "Using system settings"
                              : isDarkMode ? "Dark mode enabled" : "Light mode enabled"),
                            trailing: Switch(
                              value: isDarkMode,
                              onChanged: (value) {
                                themeProvider.setThemeMode(
                                  value ? ThemeMode.dark : ThemeMode.light
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Dark mode ${value ? 'enabled' : 'disabled'}"))
                                );
                              },
                              activeColor: Colors.amber,
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.settings_brightness),
                            title: const Text("Use System Theme"),
                            subtitle: const Text("Follow device theme settings"),
                            trailing: Switch(
                              value: isSystemMode,
                              onChanged: (value) {
                                themeProvider.setThemeMode(
                                  value ? ThemeMode.system : (isDarkMode ? ThemeMode.dark : ThemeMode.light)
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("System theme ${value ? 'enabled' : 'disabled'}"))
                                );
                              },
                              activeColor: Colors.amber,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text("Language"),
                    trailing: DropdownButton<String>(
                      value: "English",
                      underline: Container(),
                      items: const [
                        DropdownMenuItem(value: "English", child: Text("English")),
                        DropdownMenuItem(value: "Spanish", child: Text("Spanish")),
                        DropdownMenuItem(value: "French", child: Text("French")),
                      ],
                      onChanged: (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Language changed to $value"))
                        );
                      },
                    ),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text("Sign Out"),
                    onTap: () {
                      // Sign out logic would go here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Sign out functionality not implemented yet"))
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
