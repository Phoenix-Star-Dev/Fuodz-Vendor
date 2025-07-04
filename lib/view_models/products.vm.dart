import 'package:fuodz/services/alert.service.dart';
import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_routes.dart';
import 'package:fuodz/models/product.dart';
import 'package:fuodz/requests/product.request.dart';
import 'package:fuodz/view_models/base.view_model.dart';
import 'package:fuodz/views/pages/product/edit_product.page.dart';
import 'package:fuodz/views/pages/product/new_product.page.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:fuodz/extensions/context.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

class ProductViewModel extends MyBaseViewModel {
  //
  ProductViewModel(BuildContext context) {
    this.viewContext = context;
  }

  //
  ProductRequest productRequest = ProductRequest();
  List<Product> products = [];
  //
  int queryPage = 1;
  String keyword = "";
  RefreshController refreshController = RefreshController();

  void initialise() {
    fetchMyProducts();
  }

  //
  fetchMyProducts({bool initialLoading = true}) async {
    if (initialLoading) {
      setBusy(true);
      refreshController.refreshCompleted();
      queryPage = 1;
    } else {
      queryPage++;
    }

    try {
      final mProducts = await productRequest.getProducts(
        page: queryPage,
        keyword: keyword,
      );
      if (!initialLoading) {
        products.addAll(mProducts);
        refreshController.loadComplete();
      } else {
        products = mProducts;
      }
      clearErrors();
    } catch (error) {
      print("Product Error ==> $error");
      setError(error);
    }

    setBusy(false);
  }

  //
  productSearch(String value) {
    keyword = value;
    fetchMyProducts();
  }

  //
  openProductDetails(Product product) {
    Navigator.of(viewContext).pushNamed(
      AppRoutes.productDetailsRoute,
      arguments: product,
    );
  }

  void newProduct() async {
    final result = await viewContext.push(
      (context) => NewProductPage(),
    );
    //
    if (result != null) {
      fetchMyProducts();
    }
  }

  editProduct(Product product) async {
    //
    final result = await viewContext.push(
      (context) => EditProductPage(product),
    );
    if (result != null) {
      fetchMyProducts();
    }
  }

  changeProductStatus(Product product) {
    //
    AlertService.confirm(
      title: "Status Update".tr(),
      text: "Are you sure you want to".tr() +
          " ${(product.isActive != 1 ? "Activate" : "Deactivate").tr()} ${product.name}?",
      onConfirm: () {
        processStatusUpdate(product);
      },
    );
  }

  processStatusUpdate(Product product) async {
    //
    product.isActive = product.isActive == 1 ? 0 : 1;
    //
    setBusyForObject(product.id, true);
    try {
      final apiResponse = await productRequest.updateDetails(
        product,
      );
      //
      if (apiResponse.allGood) {
        fetchMyProducts();
      }
      //show dialog to present state
      AlertService.dynamic(
        type: apiResponse.allGood ? AlertType.success : AlertType.error,
        title: "Status Update".tr(),
        text: apiResponse.message,
      );
      clearErrors();
    } catch (error) {
      print("Update Status Package Type Pricing Error ==> $error");
      setError(error);
    }
    setBusyForObject(product.id, false);
  }
  //

  deleteProduct(Product product) {
    //
    AlertService.confirm(
      title: "Delete Product".tr(),
      text: "Are you sure you want to delete".tr() + " ${product.name}?",
      onConfirm: () {
        processDeletion(product);
      },
    );
  }

  processDeletion(Product product) async {
    //
    setBusyForObject(product.id, true);
    try {
      final apiResponse = await productRequest.deleteProduct(
        product,
      );
      //
      if (apiResponse.allGood) {
        products.removeWhere((element) => element.id == product.id);
      }
      //show dialog to present state
      AlertService.dynamic(
        type: apiResponse.allGood ? AlertType.success : AlertType.error,
        title: "Delete Product".tr(),
        text: apiResponse.message,
      );
      clearErrors();
    } catch (error) {
      print("delete product Error ==> $error");
      setError(error);
    }
    setBusyForObject(product.id, false);
  }
}
