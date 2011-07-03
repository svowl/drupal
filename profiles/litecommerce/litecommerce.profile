<?php
// vim: set ts=4 sw=4 sts=4 et:

/**
 * @file
 * Ecommerce CMS profile
 *
 * @category  Litecommerce connector
 * @package   Litecommerce connector
 * @author    Creative Development LLC <info@cdev.ru>
 * @copyright Copyright (c) 2010 Creative Development LLC <info@cdev.ru>. All rights reserved
 * @license   http://www.gnu.org/licenses/gpl-2.0.html GNU General Public License, version 2
 * @link      http://www.litecommerce.com/
 * @since     1.0.0
 */

/*
 * Common checking and settings of the litecommerce installation profile
 *
 * @return void
 * @since  1.0.0
 */
function _litecommerce_common_settings() {

    // Break installation if PHP version less than 5.3.0
    if (version_compare(phpversion(), '5.3.0') < 0) {
        die('LiteCommerce CMS cannot start on PHP version earlier than 5.3.0 (' . phpversion() . ' is currently used)');
    }

    if (!defined('DRUPAL_CMS_INSTALL_MODE')) {
        define('DRUPAL_CMS_INSTALL_MODE', 1);
    }

    /**
     * XLITE_INSTALL_MODE constant indicates the installation process
     */
    if (!defined('XLITE_INSTALL_MODE')) {
        define('XLITE_INSTALL_MODE', 1);
    }

    /**
     * LC_DO_NOT_REBUILD_CACHE constant prevents the automatical cache building when top.inc.php is reached
     */
    if (!defined('LC_DO_NOT_REBUILD_CACHE')) {
        define('LC_DO_NOT_REBUILD_CACHE', TRUE);
    }

    // Replace standard Drupal logo with Ecommerce CMS package logo image
    global $conf;

    $conf['theme_settings'] = array(
        'default_logo' => 0,
        'logo_path'    => 'profiles/litecommerce/lc_logo.png',
    );

    // Increase memoty_limit option value
    _litecommerce_install_increase_memory_limit(128);
}


/**
 * Returns the array of Ecommerce CMS specific tasks
 *
 * @param array $install_state An array of information about the current installation state
 *
 * @return void
 * @since  1.0.0
 */
function _litecommerce_install_tasks(array &$install_state) {
    $install_state['license_confirmed'] = isset($install_state['license_confirmed']) || (isset($_COOKIE['lc']) && '1' == $_COOKIE['lc']);

    // This call is needed to initialize setup parameters array as early as possible
    _litecommerce_get_setup_params();

    $tasks = array(
        'litecommerce_preset_locale' => array(
            'run' => INSTALL_TASK_RUN_IF_REACHED,
        ),
        'litecommerce_license_form' => array(
            'display_name' => st('License agreements'),
            'type' => 'form',
            'run' => !empty($install_state['license_confirmed']) ? INSTALL_TASK_SKIP : INSTALL_TASK_RUN_IF_REACHED,
        ),
        'litecommerce_setup_form' => array(
            'display_name' => st('Set up LiteCommerce'),
            'type' => 'form',
            'run' => INSTALL_TASK_RUN_IF_NOT_COMPLETED,
        ),
        'litecommerce_software_install' => array(
            'display_name' => st('Install LiteCommerce'),
            'type' => 'batch',
            'run' => INSTALL_TASK_RUN_IF_NOT_COMPLETED
        ),
    );

    return $tasks;
}

/**
 * Alter the default installation tasks list.
 * Extends the tasks list with the profile specific tasks
 *
 * @param array $tasks         An array of all available installation tasks
 * @param array $install_state An array of information about the current installation state
 *
 * @hook   install_tasks_alter
 * @return void
 * @since  1.0.0
 */
function litecommerce_install_tasks_alter(array &$tasks, array $install_state) {

    global $conf;

    $conf['theme_settings'] = array(
        'default_logo' => 0,
        'logo_path' => 'profiles/litecommerce/lc_logo.png',
    );

    $lc_tasks = _litecommerce_install_tasks($install_state);

    $excluded_tasks = array(
        'install_select_locale',
    );

    $new_tasks = array();

    foreach ($tasks as $key => $value) {

        if (!in_array($key, $excluded_tasks)) {
            $new_tasks[$key] = $value;
        }

        if ('install_select_profile' == $key) {
            $new_tasks['litecommerce_preset_locale'] = $lc_tasks['litecommerce_preset_locale'];
        }

        if ('install_load_profile' == $key) {
            $new_tasks['litecommerce_license_form'] = $lc_tasks['litecommerce_license_form'];
        }

        if ('install_bootstrap_full' == $key) {
            $new_tasks['litecommerce_setup_form'] = $lc_tasks['litecommerce_setup_form'];
            $new_tasks['litecommerce_software_install'] = $lc_tasks['litecommerce_software_install'];
        }
    }

    $tasks = $new_tasks;
}

/*
 * Set locale
 *
 * @param srray $install_state An array of information about the current installation state
 *
 * @return void
 * @since  1.0.0
 */
function litecommerce_preset_locale(array $install_state) {
    if ('en' != $install_state['parameters']['locale']) {
        $install_state['parameters']['locale'] = 'en';
        install_goto(install_redirect_url($install_state));
    }
}

/**
 * Implements license agreement form
 *
 * @param array $form          Form description
 * @param array &$form_state   Form state
 * @param array $install_state An array of information about the current installation state
 *
 * @hook   form
 * @return void
 * @since  1.0.0
 */
function litecommerce_license_form(array $form, array &$form_state, array &$install_state) {

    drupal_set_title(st('License agreements'));

    $license_text =<<< OUT

<br />

This package contains the following parts distributed under the <a href="http://www.gnu.org/licenses/gpl-2.0.html" target="new">GPL v2.0</a> ("GNU General Public License v.2.0"): <br />
&nbsp;&nbsp;- Drupal 7 <br />
&nbsp;&nbsp;- additional Drupal modules that may be useful for most e-commerce websites <br />
&nbsp;&nbsp;- theme developed by <a href="http://www.cdev.ru/" target="new">Creative Development LLC</a> <br />
&nbsp;&nbsp;- LiteCommerce Connector module developed by <a href="http://www.cdev.ru/" target="new">Creative Development LLC</a> <br />

<br />

Also, this package installs <a href="http://www.litecommerce.com/" target="new">LiteCommerce 3</a> e-commerce software, distributed under the <a href="http://opensource.org/licenses/osl-3.0.php" target="new">OSL 3.0</a> ("Open Software License"). LiteCommerce 3 is not a part of Drupal and can be downloaded, installed and used as a separate web application for building e-commerce websites.

<br /><br />

In order to continue the installation script, you must accept both the license agreements.

<br /><br />

OUT;

    $form = array();

    $form['license'] = array(
        '#type' => 'fieldset',
        '#title' => st('License agreements'),
        '#collapsible' => FALSE,
        '#description' => $license_text
    );

    $form['license']['content'] = array(
        '#description' => $license_text
    );

    $form['license']['license_confirmed'] = array(
        '#type' => 'checkbox',
        '#return_value' => 1,
        '#title' => st('I understand and accept <i>both</i> the license agreements')
    );

    $form['actions'] = array('#type' => 'actions');
    $form['actions']['submit'] = array(
        '#type' => 'submit',
        '#value' => st('Save and continue'),
    );

    return $form;
}

/**
 * Implements license agreement form validation
 *
 * @param array $form       Form description
 * @param array $form_state Form state
 *
 * @return void
 * @since  1.0.0
 */
function litecommerce_license_form_validate(array $form, array &$form_state) {

    if (empty($form_state['values']['license_confirmed'])) {
        form_error($form['license']['license_confirmed'], st('You should confirm the license agreement before proceeding'), 'error');
    }
}

/**
 * Implements license agreement form processing
 *
 * @param array $form       Form description
 * @param array $form_state Form state
 *
 * @return void
 * @since  1.0.0
 */
function litecommerce_license_form_submit(array $form, array &$form_state) {
    global $install_state;

    $install_state['license_confirmed'] = TRUE;
    setcookie('lc', '1');
}

/**
 * Allows the profile to alter the 'set up database' form
 *
 * :TODO: it's a hack (via system module's method emulation) - need to be reworked
 *
 * @param array $form       Form description
 * @param array $form_state Form state
 *
 * @hook   form_FORM_ID_alter
 * @return void
 * @since  1.0.0
 */
function system_form_install_settings_form_alter(array &$form, array $form_state) {

    foreach ($form['driver']['#options'] as $key => $value) {
        if ('mysql' != $key) {
            unset($form['driver']['#options'][$key]);
        }
    }

    if (count($form['driver']['#options']) == 0) {
        unset($form['driver']);
        unset($form['settings']);
        unset($form['actions']);

        $form['msg'] = array(
            '#type' => 'fieldset',
            '#title' => 'Error',
            '#description' => st('Database could not be installed because the PHP configuration does not support MySQL (PDO extension with MySQL driver support required). Please check your PHP configuration and try again.'),
        );
    }
    else {
        $form['settings']['mysql']['advanced_options']['db_prefix']['#default_value'] = 'drupal_';
        $form['settings']['mysql']['advanced_options']['db_prefix']['#description'] = st('Drupal and LiteCommerce will share the same database; to distinguish between them, it is recommended to specify a prefix for the Drupal tables (e.g. \'drupal_\'). Note: LiteCommerce tables will be created with the \'xlite_\' prefix; therefore, please avoid using the same prefix for the Drupal tables.');

        $form['settings']['mysql']['advanced_options']['unix_socket'] = $form['settings']['mysql']['advanced_options']['port'];
        $form['settings']['mysql']['advanced_options']['unix_socket']['#title'] = st('Database socket');
        $form['settings']['mysql']['advanced_options']['unix_socket']['#description'] = st('If your database server uses a non-standard socket, specify it (e.g.: /tmp/mysql-5.1.34.sock). If specified, the socket will be used for connecting to the database server instead of host:port');
        $form['settings']['mysql']['advanced_options']['unix_socket']['#maxlength'] = 255;

        $form['driver']['#disabled'] = TRUE;
        $form['driver']['#required'] = FALSE;
        $form['driver']['#description'] = st('Type of database to be used for storing your Drupal and LiteCommerce data.');

        if (is_array($form['#validate'])) {
            array_unshift($form['#validate'], 'litecommerce_install_settings_form_validate');
        }
        else {
            $form['#validate'] = array('litecommerce_install_settings_form_validate');
        }
    }
}

/**
 * Postprocessing of the 'set up database' form.
 * Extends an array $params by the data for final LC installation
 *
 * @param array $form       Form description
 * @param array $form_state Form state
 *
 * @hook   form_FORM_ID_validate
 * @return void
 * @since  1.0.0
 */
function litecommerce_install_settings_form_validate(array $form, array &$form_state) {
    $unix_socket = trim($form_state['values']['mysql']['unix_socket']);

    if (empty($unix_socket)) {
        unset($form_state['values']['mysql']['unix_socket']);
    }

    $drupal_prefix = trim($form_state['values']['mysql']['db_prefix']);

    $xlite_prefix = get_xlite_tables_prefix();

    if ($drupal_prefix == $xlite_prefix) {
        form_set_error('mysql][db_prefix', st('A prefix for the Drupal tables cannot be :db_prefix as it is reserved for the LiteCommerce tables.', array(':db_prefix' => $xlite_prefix)));
    }
}

/**
 * Implements the 'Set up LiteCommerce' form
 *
 * @param array $form          Form description
 * @param array &$form_state   Form state
 * @param array $install_state An array of information about the current installation state
 *
 * @hook   form
 * @return void
 * @since  1.0.0
 */
function litecommerce_setup_form(array $form, array &$form_state, array &$install_state) {

    drupal_set_title(st('Install LiteCommerce'));

    if (_litecommerce_include_lc_files()) {

        $form['litecommerce_settings'] = array(
            '#type' => 'fieldset',
            '#title' => st('LiteCommerce installation settings'),
            '#collapsible' => FALSE,
            '#description' => st('LiteCommerce software will be installed in the directory <i>:lcdir</i> <br />Please choose the installation options below and continue.<br /><br />', array(':lcdir' => _litecommerce_get_litecommerce_dir())),
            '#weight' => 10,
        );

        $form['litecommerce_settings']['lc_install_demo'] = array(
            '#type' => 'checkbox',
            '#title' => st('Install sample catalog'),
            '#default_value' => '1',
            '#description' => st('Specify whether you would like to setup sample categories and products?'),
            '#weight' => 20,
        );

        $form['actions'] = array('#type' => 'actions');
        $form['actions']['save'] = array(
            '#type' => 'submit',
            '#value' => st('Save and continue'),
        );

        if (true == _litecommerce_is_lc_installed()) {

            $form['litecommerce_installed'] = array(
                '#type' => 'fieldset',
                '#title' => st('Existing LiteCommerce installation found'),
                '#collapsible' => FALSE,
                '#description' => st('An existing LiteCommerce installation has been found. If you choose to proceed, all the existing data will be lost.'),
                '#weight' => 5,
            );

            $form['litecommerce_installed']['lc_skip_installation'] = array(
                '#type' => 'checkbox',
                '#title' => st('Do not install LiteCommerce'),
                '#default_value' => '1',
                '#weight' => 10,
                '#attributes' => array('onClick' => "javascript: if (this.checked) document.getElementById('edit-litecommerce-settings').style.display='none'; else document.getElementById('edit-litecommerce-settings').style.display='block';"),
            );

            drupal_set_message(st('A previous LiteCommerce installation found!'), 'warning');


        }
    }
    else {
        $form['litecommerce_settings'] = array(
            '#type'        => 'fieldset',
            '#title'       => st('LiteCommerce installation settings'),
            '#description' => 'Installation cannot proceed because of an error'
        );
    }

    return $form;
}

/**
 * Processes the 'Set up LiteCommerce' form
 *
 * @param array $form       Form description
 * @param array $form_state Form state
 *
 * @hook   form_FORM_ID_submit
 * @return void
 * @since  1.0.0
 */
function litecommerce_setup_form_submit(array $form, array &$form_state) {
    $params = _litecommerce_get_setup_params();
    $params['demo'] = isset($form_state['values']['lc_install_demo']) && !empty($form_state['values']['lc_install_demo']);

    if (isset($form_state['values']['lc_skip_installation']) && !empty($form_state['values']['lc_skip_installation'])) {
        variable_set('lc_skip_installation', TRUE);
    }

    $params['setup_passed'] = TRUE;

    variable_set('lc_setup_params', $params);
}

/**
 * Implements LiteCommerce installation batch process.
 * Prepares the array of actions that need to be completed during the installation process
 *
 * @param array $install_state Installation state
 *
 * @return void
 * @since  1.0.0
 */
function litecommerce_software_install(array &$install_state) {

    $batch = array();
    $skip_lc_installation = variable_get('lc_skip_installation', FALSE);

    if (false == $skip_lc_installation) {
        $steps = array();

        $steps[] = array(
            'function' => 'doUpdateConfig',
            'message'  => st('Config file updated'),
        );
        $steps[] = array(
            'function' => 'doInstallDirs',
            'message'  => st('Directories installed'),
        );
        $steps[] = array(
            'function' => 'doRemoveCache',
            'message'  => st('Prepared for building cache'),
        );
        $steps[] = array(
            'function' => 'doPrepareFixtures',
            'message'  => st('Fixtures prepared'),
        );
        $steps[] = array(
            'function' => 'doBuildCache',
            'message'  => st('Building cache. Step #1 passed'),
        );
        $steps[] = array(
            'function' => 'doBuildCache',
            'message'  => st('Building cache. Step #2 passed'),
        );
        $steps[] = array(
            'function' => 'doBuildCache',
            'message'  => st('Building cache. Step #3 passed'),
        );
        $steps[] = array(
            'function' => 'doBuildCache',
            'message'  => st('Building cache. Step #4 passed'),
        );
        $steps[] = array(
            'function' => 'doBuildCache',
            'message'  => st('Building cache. Step #5 passed'),
        );

        $operations = array();

        foreach ($steps as $step) {
            $operations[] = array('_litecommerce_software_install_batch', array($step));
        }

        $batch = array(
            'operations'    => $operations,
            'title'         => st('Installing LiteCommerce'),
            'error_message' => st('An error occurred during the installation.'),
            'finished'      => '_litecommerce_software_install_finished',
        );
    }

    return $batch;
}

/**
 * Performs the batch process step
 *
 * @param array $step    Step description
 * @param mixed $context Context
 *
 * @return void
 * @since  1.0.0
 */
function _litecommerce_software_install_batch(array $step, &$context) {

    // Function name
    $function = $step['function'];

    if (_litecommerce_include_lc_files()) {

        if (function_exists($function)) {

            $params = _litecommerce_get_setup_params();

            // Suppress any direct output from the function
            ob_start();

            if (in_array($function, array('doUpdateConfig', 'doPrepareFixtures'))) {
                $result = $function($params);
            }
            else {
                $result = $function();
            }

            $output = ob_get_contents();

            ob_end_clean();

            x_install_log($function, array('result' => $result, 'output' => $output));

            if (false === $result) {
                // Print output and break the batch process if function is failed
                drupal_set_message(check_plain(sprintf('Function %s failed.', $function)), 'error');
                die($output);
            }

            $context['results'][] = $step['function'];
            $context['message'] = $step['message'];
        }
    }
}

/**
 * Detect the LiteCommerce directory.
 * Returns a absolute path of a directory or null if not found
 *
 * @return string
 * @since  1.0.0
 */
function _litecommerce_get_litecommerce_dir() {
    $result = NULL;

    if (LCConnector_Install::isLCExists()) {
        $result = LCConnector_Install::getLCCanonicalDir();
    }
    else {
        drupal_set_message(
            st(
                'Installation cannot proceed because of LiteCommerce software not found. '
                . 'LiteCommerce software is a part of Ecommerce CMS package and it must be located '
                . 'within LC connector module directory.'
            ),
            'error'
        );
    }

    return $result;
}

/**
 * Finish the LiteCommerce installation batch process
 *
 * @param boolean $success    Flag
 * @param mixed   $results    Results
 * @param mixed   $operations Operations
 *
 * @return void
 * @since  1.0.0
 */
function _litecommerce_software_install_finished($success, $results, $operations) {

    if (!$success) {
        drupal_set_message(st('LiteCommerce installation failed.'), 'error');
    }
}

/**
 * Allows the profile to alter the site configuration form
 *
 * @param array $form       Form description
 * @param array $form_state Form state
 *
 * @hook   form_FORM_ID_alter
 * @return void
 * @since  1.0.0
 */
function litecommerce_form_install_configure_form_alter(array &$form, array &$form_state) {

    // Pre-populate the site name with the server name.
    $form['site_information']['site_name']['#default_value'] = st('My Ecommerce CMS');

    if (is_array($form['#submit'])) {
        array_push($form['#submit'], 'litecommerce_form_install_configure_form_submit');
    }
    else {
        $form['#submit'] = array('litecommerce_form_install_configure_form_submit');
    }
}

/**
 * Postprocessing of the site configuration form.
 * Extends an array $params by the data for final LC installation
 *
 * @param array $form       Form description
 * @param array $form_state Form state
 *
 * @hook   form_FORM_ID_submit
 * @return void
 * @since  1.0.0
 */
function litecommerce_form_install_configure_form_submit(array &$form, array &$form_state) {
    $result = FALSE;

    $params = _litecommerce_get_setup_params();

    $params['name'] = trim($form_state['values']['account']['name']); // Admin username
    $params['login'] = trim($form_state['values']['account']['mail']); // Admin e-mail
    $params['password'] = trim($form_state['values']['account']['pass']); // Admin password
    $params['site_name'] = trim($form_state['values']['site_name']); // Site name
    $params['site_mail'] = trim($form_state['values']['site_mail']); // Site e-mail
    $params['site_default_country'] = trim($form_state['values']['site_default_country']); // Site default country

    variable_set('lc_setup_params', $params);

    // Update user with specified data
    $account = user_load(1);

    $edit = array(
        'uid' => 1,
        'mail'   => $params['login'],
        'roles'  => array(
            DRUPAL_AUTHENTICATED_RID        => TRUE,
            variable_get('user_admin_role') => TRUE,
        )
    );

    $account->passwd = $params['password'];

    user_save($account);

    // Reset service variables which were used during installation process
    foreach (array('lc_skip_installation', 'lc_setup_params') as $var) {
        variable_del($var);
    }
}

/**
 * Checks availability and includes LiteCommerce installation scripts
 *
 * @return void
 * @since  1.0.0
 */
function _litecommerce_include_lc_files() {
    _litecommerce_common_settings();

    if (!($result = LCConnector_Install::includeLCFiles())) {
        drupal_set_message(st('LiteCommerce software not found'), 'error');
    }

    return $result;
}

/**
 * Detects an LC Connector module directory.
 * Returns a realpath of a directory or URI or empty string if module not found
 *
 * @param boolean $realpath If true then realpath of the directory will be returned. Else a URI will be returned. OPTONAL
 *
 * @return string
 * @since  1.0.0
 */
function detect_lc_connector_uri($realpath = FALSE) {
    $result = &drupal_static(__FUNCTION__, NULL);

    if (!isset($result)) {
        $files = drupal_system_listing('/^lc_connector\.info$/', 'modules', 'name', 0);

        if (!empty($files)) {
            $result = dirname($files['lc_connector']->uri);
        }

        if (!isset($result) || FALSE == realpath($result)) {
            drupal_set_message(st('Installation cannot continue because the LC Connector module could not be found. The module is required for installing the Ecommerce CMS package.'), 'error');
            $result = '';
        }
    }

    return (!empty($result) && $realpath ? realpath($result) : $result);
}

/**
 * Checks if LiteCommerce has already been installed
 *
 * @return boolean
 * @since  1.0.0
 */
function _litecommerce_is_lc_installed() {
    $result = FALSE;

    if (_litecommerce_include_lc_files()) {
        $params  = _litecommerce_get_setup_params();
        $message = NULL;
        $result  = isLiteCommerceInstalled($params, $message);
    }

    return $result;
}

/**
 * Prepare array of LiteCommerce setup parameters
 *
 * @return array
 * @since  1.0.0
 */
function _litecommerce_get_setup_params() {
    _litecommerce_common_settings();

    $lc_install_file = detect_lc_connector_uri() . DIRECTORY_SEPARATOR . 'classes' . DIRECTORY_SEPARATOR . 'Install.php';

    if (file_exists($lc_install_file)) {
        require_once $lc_install_file;
    }

    if (class_exists('LCConnector_Install')) {
        $db_params = LCConnector_Install::getDatabaseParams();
        $params    = variable_get('lc_setup_params');

        if (empty($params) && !empty($db_params)) {
            $params = $db_params;

            $url = parse_url(LCConnector_Install::getDrupalBaseURL() . '/modules/lc_connector/litecommerce');
            $params['xlite_http_host'] = $url['host'] . (empty($url['port']) ? '' : (':' . $url['port']));
            $params['xlite_web_dir'] = $url['path'];
        }
    }
    else {
        $params = array();
        drupal_set_message(st('LC Connector module not found (:file)', array(':file' => $lc_install_file)), 'error');
    }

    return $params;
}

/**
 * Increase memory_limit value
 *
 * @param integer $new_value Value to set
 *
 * @return void
 * @since  1.0.0
 */
function _litecommerce_install_increase_memory_limit($new_value) {
    $current_value = @ini_get('memory_limit');

    if (!empty($current_value)) {

        preg_match('/(\d+)(.?)/i', $current_value, $match);

        if ('M' == strtoupper($match[2])) {
            $current_value = intval($match[1]);
        }
        elseif ('G' == strtoupper($match[2])) {
            $current_value = $new_value;
        }
        else {
            $current_value = 0;
        }
    }

    if (intval($new_value) > intval($current_value)) {
        @ini_set('memory_limit', sprintf('%dM', $new_value));
    }
}
