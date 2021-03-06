part of 'models.dart';

abstract class PackageTab {
  /// The title of the tab
  final String title;

  /// The body of the tab as HTML.
  final String content;

  PackageTab({@required this.title, @required this.content});

  static String capitalizeFirstLetter(String s) =>
      (s?.isNotEmpty ?? false) ? '${s[0].toUpperCase()}${s.substring(1)}' : s;

  factory PackageTab.fromElement(Element element) {
    String title = element.attributes['data-name'];
    String content = element.innerHtml;
    return getPackageTab(title: title, content: content);
  }

  static PackageTab getPackageTab({
    @required String title,
    @required String content,
  }) {
    switch (title) {
      case TabTitle.readme:
      case "README.md":
        {
          return ReadMePackageTab(
            content: content,
          );
        }
      case TabTitle.changelog:
      case "CHANGELOG.md":
        {
          return ChangelogPackageTab(
            content: content,
          );
        }
      case TabTitle.example:
      case "Example":
        {
          return ExamplePackageTab(
            content: content,
          );
        }
      case TabTitle.installing:
      case "Installing":
        {
          return InstallingPackageTab(
            content: content,
          );
        }
      case TabTitle.versions:
        {
          return VersionsPackageTab(
            content: content,
          );
        }
      case TabTitle.analysis:
      case "Analysis":
        {
          return AnalysisPackageTab(
            content: content,
          );
        }
      default:
        title = RegExp(r'-(.*)-tab-').firstMatch(title).group(1);
        return GenericPackageTab(
          title: capitalizeFirstLetter(title),
          content: content,
        );
    }
  }

  Map<String, dynamic> toJson() => {
        "title": this.title,
        "content": this.content,
      };

  factory PackageTab.fromJson(Map<String, dynamic> json) {
    return getPackageTab(
      title: json["title"],
      content: json["content"],
    );
  }
}

class ReadMePackageTab extends PackageTab {
  ReadMePackageTab({@required String content})
      : super(title: "README.md", content: content);
}

class ChangelogPackageTab extends PackageTab {
  ChangelogPackageTab({@required String content})
      : super(title: "CHANGELOG.md", content: content);
}

class ExamplePackageTab extends PackageTab {
  ExamplePackageTab({@required String content})
      : super(title: "Example", content: content);
}

class InstallingPackageTab extends PackageTab {
  InstallingPackageTab({@required String content})
      : super(title: "Installing", content: content);
}

class VersionsPackageTab extends PackageTab {
  VersionsPackageTab({@required String content})
      : super(title: "Versions", content: content);
}

class AnalysisPackageTab extends PackageTab {
  AnalysisPackageTab({@required String content})
      : super(title: "Analysis", content: content) {
    final document = parse(content);
    final scores = _extractScores(document);
    popularity = scores['popularity'];
    health = scores['health'];
    maintenance = scores['maintenance'];
    overall = scores['overall'];
    final dependencyTable = _extractDependencyTable(document);
    dependencies = _getDirectDependencies(dependencyTable);
  }

  ///  Describes how popular the package is relative to other packages
  int popularity;

  /// Code health derived from static analysis.
  int health;

  /// Reflects how tidy and up-to-date the package is.
  int maintenance;

  /// Weighted score of the above.
  int overall;

  List<BasicDependency> dependencies;

  Map<String, int> _extractScores(Document element) {
    final scoresTable = element.querySelector("#scores-table");
    List<Element> tableRows = scoresTable.querySelectorAll('tr');
    Map<String, int> scores = {};
    for (final row in tableRows) {
      final scoreName = row
          .querySelector('.tooltip-dotted')
          .text
          .replaceFirst(':', '')
          .toLowerCase();
      final scoreValue = row.querySelector('.score-percent').text;
      scores[scoreName] = int.tryParse(scoreValue);
    }
    return scores;
  }

  List<BasicDependency> _getDirectDependencies(Element dependencyTable) {
    bool isHeaderRow(Element tableRow) {
      const String tableHeaderTag = 'th';
      if (tableRow.children
          .any((childNode) => childNode.localName == tableHeaderTag)) {
        return true;
      }
      return false;
    }

    List<BasicDependency> dependencies = [];
    var dependencyElements = dependencyTable.querySelectorAll('tr');
    // removing the main table header.
    dependencyElements
        .removeWhere((element) => element.querySelectorAll('th').length == 4);
    for (final row in dependencyElements) {
      if (!isHeaderRow(row)) {
        dependencies.add(_extractDependency(row));
      }
    }
    return dependencies;
  }

  Element _extractDependencyTable(Document document) =>
      document.querySelector('.dependency-table');

  BasicDependency _extractDependency(Element row) {
    var versionString = row.children[2].text;
    var version;
    if (versionString.isNotEmpty) {
      version = semver.Version.parse(versionString);
    }
    var versionConstraintText = row.children[1].text;
    var versionConstraint;
    if (versionConstraintText.isNotEmpty) {
      versionConstraint = semver.VersionConstraint.parse(versionConstraintText);
    }

    return BasicDependency(
      name: row.children[0].text,
      constraint: versionConstraint,
      resolved: version,
    );
  }
}

class GenericPackageTab extends PackageTab {
  GenericPackageTab({@required title, @required String content})
      : super(title: title, content: content);
}

class TabTitle {
  static const String readme = "-readme-tab-";
  static const String changelog = "-changelog-tab-";
  static const String example = "-example-tab-";
  static const String installing = "-installing-tab-";
  static const String versions = "-versions-tab-";
  static const String analysis = "-analysis-tab-";
}
