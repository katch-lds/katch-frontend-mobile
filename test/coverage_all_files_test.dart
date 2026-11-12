// Gerado por `dart run tool/coverage_all_files.dart`. Não editar.
//
// Importa todos os ficheiros de lib/ do âmbito da cobertura, para
// os ficheiros sem testes contarem como não cobertos (plano de
// testes do frontend mobile, secção 10).

// ignore_for_file: unused_import

import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/app/app_config.dart';
import 'package:katch_mobile/app/app_dependencies.dart';
import 'package:katch_mobile/app/app_scope.dart';
import 'package:katch_mobile/app/auth_gate.dart';
import 'package:katch_mobile/app/home_shell.dart';
import 'package:katch_mobile/app/katch_app.dart';
import 'package:katch_mobile/core/api_client.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/core/clock.dart';
import 'package:katch_mobile/core/connection_monitor.dart';
import 'package:katch_mobile/core/credential_provider.dart';
import 'package:katch_mobile/core/http_api_client.dart';
import 'package:katch_mobile/core/input_rules.dart';
import 'package:katch_mobile/core/url.dart';
import 'package:katch_mobile/models/api_error_dto.dart';
import 'package:katch_mobile/models/change_password_request.dart';
import 'package:katch_mobile/models/field_errors.dart';
import 'package:katch_mobile/models/json.dart';
import 'package:katch_mobile/models/login_request.dart';
import 'package:katch_mobile/models/login_response.dart';
import 'package:katch_mobile/models/reference_item_dto.dart';
import 'package:katch_mobile/models/register_candidate_request.dart';
import 'package:katch_mobile/models/user_type.dart';
import 'package:katch_mobile/polling/polling_loop.dart';
import 'package:katch_mobile/screens/account/account_screen.dart';
import 'package:katch_mobile/screens/account/change_password_screen.dart';
import 'package:katch_mobile/screens/auth/login_screen.dart';
import 'package:katch_mobile/screens/auth/register_screen.dart';
import 'package:katch_mobile/screens/auth/register_success_screen.dart';
import 'package:katch_mobile/services/auth_service.dart';
import 'package:katch_mobile/services/http_auth_service.dart';
import 'package:katch_mobile/services/http_reference_list_service.dart';
import 'package:katch_mobile/services/reference_list_service.dart';
import 'package:katch_mobile/services/response_reader.dart';
import 'package:katch_mobile/session/secure_session_storage.dart';
import 'package:katch_mobile/session/session.dart';
import 'package:katch_mobile/session/session_manager.dart';
import 'package:katch_mobile/session/session_status.dart';
import 'package:katch_mobile/session/session_storage.dart';
import 'package:katch_mobile/state/account_controller.dart';
import 'package:katch_mobile/state/change_password_controller.dart';
import 'package:katch_mobile/state/failure_messages.dart';
import 'package:katch_mobile/state/load_status.dart';
import 'package:katch_mobile/state/login_controller.dart';
import 'package:katch_mobile/state/reference_data_store.dart';
import 'package:katch_mobile/state/register_controller.dart';
import 'package:katch_mobile/widgets/connection_banner.dart';
import 'package:katch_mobile/widgets/form_message.dart';

void main() {
  test('importa todos os ficheiros de lib/', () {
    expect(true, isTrue);
  });
}
