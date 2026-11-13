import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../core/device_file_picker.dart';
import '../core/input_rules.dart';
import '../models/field_errors.dart';
import '../models/file_selection.dart';
import '../models/profile_requests.dart';
import '../services/candidate_profile_service.dart';
import 'failure_messages.dart';
import 'load_status.dart';
import 'profile_store.dart';

/// Hiperligação em edição em M06, com uma chave estável para o ecrã.
final class LinkDraft {
  LinkDraft(this.key, this.url);

  final int key;
  String url;
}

/// Estado de M06: fotografia, curriculum vitae e hiperligações (modelo de
/// classes, 8.3; RF010, RF011, RF012).
///
/// Valida localmente o formato e a dimensão dos ficheiros (P01, P02) e os
/// endereços (P10) **antes do primeiro pedido**; depois envia a fotografia, o
/// CV e as hiperligações, por esta ordem, e volta a pedir o perfil.
class ProfileFilesController extends ChangeNotifier {
  ProfileFilesController({
    required CandidateProfileService service,
    required ProfileStore profile,
    required DeviceFilePicker picker,
  }) : _service = service,
       _profile = profile,
       _picker = picker;

  static const photoField = 'photo';
  static const cvField = 'cv';
  static const linksField = 'urls';

  /// Campo do motivo da hiperligação `index` (o mesmo nome da API v02).
  static String linkField(int index) => 'urls[$index]';

  /// Campo do ficheiro nas rejeições do servidor (ERR-11).
  static const _uploadField = 'file';

  final CandidateProfileService _service;
  final ProfileStore _profile;
  final DeviceFilePicker _picker;

  FileSelection? _photo;
  FileSelection? _cv;
  List<LinkDraft> _links = [];
  int _nextKey = 0;
  FieldErrors _errors = FieldErrors();
  LoadStatus _status = LoadStatus.idle;
  String? _errorMessage;
  bool _disposed = false;

  /// Fotografia escolhida e ainda por enviar.
  FileSelection? get photo => _photo;

  /// Curriculum vitae escolhido e ainda por enviar.
  FileSelection? get cv => _cv;

  List<LinkDraft> get linkDrafts => List.unmodifiable(_links);

  List<String> get links => [for (final link in _links) link.url];

  FieldErrors get errors => _errors;

  LoadStatus get status => _status;

  String? get errorMessage => _errorMessage;

  /// Preenche as hiperligações com as do perfil.
  void load() {
    _links = [
      for (final url in _profile.profile?.links ?? const <String>[])
        LinkDraft(_nextKey++, url),
    ];
    _notify();
  }

  /// Escolhe a fotografia e indica logo o motivo, se não for aceite (P01).
  Future<void> pickPhoto() async {
    final file = await _picker.pickImage();
    if (file == null) {
      return;
    }
    _photo = file;
    _setReason(photoField, InputRules.photoError(file));
  }

  /// Escolhe o curriculum vitae e indica logo o motivo, se não for aceite
  /// (P02).
  Future<void> pickCv() async {
    final file = await _picker.pickPdf();
    if (file == null) {
      return;
    }
    _cv = file;
    _setReason(cvField, InputRules.cvError(file));
  }

  /// Acrescenta uma hiperligação vazia; a quarta é recusada (P10).
  bool addLink() {
    if (_links.length >= InputRules.maxLinks) {
      _errors.add(linksField, InputRules.tooManyLinksReason);
      _notify();
      return false;
    }
    _links.add(LinkDraft(_nextKey++, ''));
    _errors.remove(linksField);
    _notify();
    return true;
  }

  void setLink(int index, String url) {
    _links[index].url = url;
    _errors.remove(linkField(index));
    _notify();
  }

  void removeLink(int index) {
    _links.removeAt(index);
    _clearLinkErrors();
    _notify();
  }

  bool validate() {
    final errors = FieldErrors();
    final photo = _photo;
    final cv = _cv;
    final photoReason = photo == null ? null : InputRules.photoError(photo);
    if (photoReason != null) {
      errors.add(photoField, photoReason);
    }
    final cvReason = cv == null ? null : InputRules.cvError(cv);
    if (cvReason != null) {
      errors.add(cvField, cvReason);
    }
    if (_links.length > InputRules.maxLinks) {
      errors.add(linksField, InputRules.tooManyLinksReason);
    }
    final urls = _cleanLinks();
    for (var index = 0; index < urls.length; index++) {
      if (!InputRules.isValidLink(urls[index])) {
        errors.add(linkField(index), InputRules.linkReason);
      }
    }
    _errors = errors;
    _notify();
    return errors.isEmpty;
  }

  /// Envia a fotografia, o CV e as hiperligações; devolve `true` se tudo foi
  /// gravado.
  Future<bool> save() async {
    if (_status == LoadStatus.loading || !validate()) {
      return false;
    }
    _status = LoadStatus.loading;
    _errorMessage = null;
    _notify();
    var uploaded = false;
    var saved = false;
    try {
      final photo = _photo;
      if (photo != null) {
        await _upload(photoField, () => _service.uploadPhoto(photo));
        _photo = null;
        uploaded = true;
      }
      final cv = _cv;
      if (cv != null) {
        await _upload(cvField, () => _service.uploadCv(cv));
        _cv = null;
        uploaded = true;
      }
      final urls = _cleanLinks();
      if (!listEquals(urls, _profile.profile?.links ?? const <String>[])) {
        _profile.update(await _service.setLinks(SetLinksRequest(urls)));
      }
      _links = [for (final url in urls) LinkDraft(_nextKey++, url)];
      _status = LoadStatus.loaded;
      saved = true;
    } on ApiRejection catch (rejection) {
      _status = LoadStatus.failed;
      for (final field in rejection.error.fields) {
        _errors.add(field.field, field.reason);
      }
      _errorMessage = rejection.error.message;
    } on ApiException catch (failure) {
      _status = LoadStatus.failed;
      _errorMessage = failureMessage(failure);
    }
    if (uploaded) {
      await _profile.refresh();
    }
    _notify();
    return saved;
  }

  /// Envia um ficheiro; o motivo do servidor (campo `file`) fica no campo do
  /// ficheiro enviado.
  Future<void> _upload(String field, Future<void> Function() send) async {
    try {
      await send();
    } on ApiRejection catch (rejection) {
      final reason = rejection.error.reasonFor(_uploadField);
      if (reason != null) {
        _errors.add(field, reason);
      }
      _errorMessage = rejection.error.message;
      rethrow;
    }
  }

  List<String> _cleanLinks() => [
    for (final link in _links)
      if (link.url.trim().isNotEmpty) link.url.trim(),
  ];

  void _clearLinkErrors() {
    for (final field in _errors.fields.toList()) {
      if (field.startsWith(linksField)) {
        _errors.remove(field);
      }
    }
  }

  void _setReason(String field, String? reason) {
    _errors.remove(field);
    if (reason != null) {
      _errors.add(field, reason);
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
